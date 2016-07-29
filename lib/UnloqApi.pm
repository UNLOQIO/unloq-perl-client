package UnloqApi;

use strict;
use warnings;

use Moose;
use LWP::UserAgent;
use JSON qw/decode_json/;
use Digest::SHA qw/hmac_sha256_base64/;
use UnloqResults;

has key => (
    is => 'rw',
    isa => 'Str',
    required => 1,
    default => ""
);

has secret => (
    is => 'rw',
    isa => 'Str',
    required => 1,
    default => ""
);

my $api_url = "https://api.unloq.io";
my $api_version = 1;

=head2 getPath

    Helper function, returns the full API path along with the given path

=cut

sub getPath {
    my $self = shift;
    my $path = shift;
    my $withVersion = shift || 1;
    
    my $full = (!$withVersion) ? $api_url.$path
                               : $api_url."/v".$api_version.$path;
    
    return $full;
}

=head2 request

    Performs an API request using LWP::UserAgent

=cut

sub request {
    my $self = shift;
    my $method = shift || "GET";
    my $path = shift;
    my $data = shift;
    my $includeVersion = shift || 1;
    
    my $url = $self->getPath($path,$includeVersion);
    
    my $ua = LWP::UserAgent->new;
    
    $ua->timeout(120);
    $ua->default_header('X-Api-Key' => $self->key);
    $ua->default_header('X-Api-Secret' => $self->secret);
    $ua->default_header('Content-Type' => 'application/x-www-form-urlencoded');
    $ua->ssl_opts(verify_hostname => 1);
    
    my $response;
    if ($method eq "POST") {
        $response = $ua->post($url, $data);
    }else{
        $response = $ua->get($url);
    }
    
    my $results = new UnloqResults();
    
    my $res = decode_json( $response->content() );
    
    if ($res->{type} eq "error") {
        if ($res->{code} eq "APPLICATION.NOT_FOUND") {
            $res->{message} = "Invalid API Key or API Secret";
        }
        
        $results->set_error($res->{code},$res->{message});
        
        return $results;        
    }else{
        $results->set_success($res->{data});
    }
    
    return $results;
}

=head2 token

    Returns the associated user data of a previously generated access token.
    Once an access token is generated, it is available only once and expires after 1 minute.
    
    Parameters:
        - token (string, required) - previously user-generated authentication token.
        - sid (string) - The session ID, generated by your application for the authenticated user. This is used for remote logout only.
        - duration (integer) - The number of seconds the session is considered active, before UNLOQ will consider it terminated.

=cut

sub token {
    my $self = shift;
    my ($token,$sid,$duration) = @_;
    
    if (!$token || length($token) < 129) {
        return new UnloqResults()->set_error("The UAuth access token is not valid","ACCESS_TOKEN");
    }
    
    my $data = {
            token    => $token,
            sid      => $sid,
            duration => $duration
        };
    
    my $res = $self->request("POST","/token",$data);
    
    if (!$res->error) {
        if (!$res->{data}->{id} || !$res->{data}->{email}) {
            return new UnloqResults()->set_error("The UAuth response does not contain login information.", "API_ERROR");
        }
    }
    
    return $res->to_hash();
}

=head2 token_session

    When an application that implements UNLOQ (that has remote logout enabled), is unable to send the session id and its duration via the first /token call, it may use this endpoint as a backup.
    
    Parameters:
        - token (string, required) - previously user-generated authentication token.
        - sid (string, required) - The session ID, generated by your application for the authenticated user.
        - duration (integer) - The number of seconds the session is considered active, before UNLOQ will consider it terminated.

=cut

sub token_session {
    my $self = shift;
    my ($token,$sid,$duration) = @_;
    
    my $data = {
            token    => $token,
            sid      => $sid,
            duration => $duration
        };
    
    my $res = $self->request("POST","/token/session",$data);
    
    return $res->to_hash();
}

=head2 authenticate

    Initiates an authentication request for the given e-mail. This is a Server-to-Server implementation of the UNLOQ authentication flow.
    
    Parameters:
        - email (string, required) - The UNLOQ User e-mail that has initiated the authentication process.
        - method (enum) - Initiates the authentication request with the specified method. Values: UNLOQ, EMAIL, OTP.
        - ip (string) - The originating IP address that will be displayed on the user's device.
        - token (integer) - Optional, the OTP token the user has provided. This is required for subsequent authentication requests, after a user has denied the request.

=cut

sub authenticate {
    my $self = shift;
    my ($email,$method,$ip,$token) = @_;
    
    if (!$email) {
        return new UnloqResults()->set_error("The UAuth response does not contain login information.", "API_ERROR");
    }
    
    my $data = {
            email  => $email,
            method => $method,
            ip     => $ip,
            token  => $token
        };
    
    my $res = $self->request("POST","/authenticate",$data);
    
    return $res->to_hash();
}

=head2 authorize

    Initiates an authorisation request and sends it to the specified user's device.
    For the authorisation request to work, the user must have previously authenticated in the application.
    
    Parameters:
        - code (string, required) - The authorisation action code to use. This will be used as a template.
        - *unloq_id (integer, required) - The UnloqID of the target user. The user must have previously authenticated to the requested application.
        - reference (string, required) - An authorisation reference that will be displayed on the user's device. This can be viewed as an external id, with a maximum length of 20 characters.
        - data (hash) - Any number of variable names, defined in the authorisation action.

=cut

sub authorize {
    my $self = shift;
    my ($code,$unloq_id,$reference,$data) = @_;
    
    if (!$code) {
        return new UnloqResults()->set_error("Authorisation action not provided.", "API_ERROR");
    }
    
    if (!$unloq_id || !$reference) {
        return new UnloqResults()->set_error("Required parameters not provided.", "API_ERROR");
    }
    
    $data->{unloq_id} = $unloq_id;
    $data->{reference} = $reference;
    
    my $res = $self->request("POST","/authorize/".$code,$data);
    
    return $res->to_hash();
}

=head2 encryption

    Initiates an encryption key request and sends it to the specified user's device.
    For the encryption key request to work, the application must have encryption keys enabled and the user must have previously authenticated to it.
    
    Parameters:
        - unloq_id (integer, required) - The UnloqID of the target user. The user must have previously authenticated to the requested application.
        - message (string) - An optional message that will appear on the user's device. You can use this field to specify why you need access to the user's encryption key.
        - requester_id (integer) - If you specify this field, you basically state that the encryption key was requested by a specific UNLOQ user. The user's email and information will also appear on the device.
        - public_key (string) - An PEM-encoded RSA public key (-----BEGIN PUBLIC KEY----- and -----END PUBLIC KEY-----) that the device will use to encrypt the user's encryption key.

=cut

sub encryption {
    my $self = shift;
    my ($unloq_id,$message,$requester_id,$public_key) = @_;
    
    if (!$unloq_id) {
        return new UnloqResults()->set_error("Required parameters not provided.", "API_ERROR");
    }
    
    my $data = {
            unloq_id => $unloq_id,
            message => $message,
            requester_id => $requester_id,
            public_key => $public_key
        };
    
    my $res = $self->request("POST","/encryption/user/",$data);
    
    return $res->to_hash();
}

=head2 login

    Implementing the Unloq auth protocol, this route is called when a user is redirected back to us
    with a valid access token found in the querystring. We then proceed to request the user information
    from UNLOQ, and, based on the resulting user from the local database, we log him in
    
    Parameters:
        - email (string, required) - The UNLOQ User e-mail that has initiated the authentication process.
        - method (enum) - Initiates the authentication request with the specified method. Values: UNLOQ, EMAIL, OTP.
        - ip (string) - The originating IP address that will be displayed on the user's device.
        - token (integer) - Optional, the OTP token the user has provided. This is required for subsequent authentication requests, after a user has denied the request.
=cut

sub login {
    my $self = shift;
    my ($email,$method,$ip,$token) = @_;
    
    my $res = $self->authenticate($email,$method,$ip,$token);
    
    if (defined $res->{data}) {
        return $self->token($res->{data}->{token});
    }else{
        return $res;
    }
}

=head2 login

    The call will verify the signature of an incoming webhook.
    
    Parameters:
        - $data - the incoming POST data.
        - $signature - the X-Unloq-Signature header.
    
    Steps:
      1. Create a string with the URL PATH(PATH ONLY), including QS and the first/
      2. Sort the data alphabetically,
      3. Append each KEY,VALUE to the string
      4. HMAC-SHA256 with the app's api secret
      5. Base64-encode the signature.

=cut

sub verifySignature {
    my $self = shift;
    my ($path,$data,$signature) = @_;
    
    return 0 if (!$path || !$signature);
    
    $path = "/".$path if (substr($path,0,1) ne "/");
    
    my @sorted = sort {$a cmp $b} keys $data;
    
    foreach my $key (@sorted){
        next if ($key eq "uauth");
        my $value = $data->{$key} ? $data->{$key} : "";
        $path = $path.$key.$value;
    }

    my $signHash = hmac_sha256_base64($path, $self->secret);
    
    return ($signature ne $signHash) ? 0 : 1;
}
1;