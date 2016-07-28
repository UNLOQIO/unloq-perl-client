package Unloq::Controller::Authenticate;
use Mojo::Base 'Mojolicious::Controller';

use lib 'lib';
use UnloqApi;

my $key = "Your API Key";
my $secret = "Your API secret";

sub authenticate {
  my $self = shift;

  my $unloq = new UnloqApi(key => $key, secret => $secret);
  
  my $token = $unloq->authenticate('john@doe.com');
  
  $self->render( json => $token);
}

sub authorize {
  my $self = shift;

  my $unloq = new UnloqApi(key => $key, secret => $secret);
  
  my $user_data = $unloq->authorize("transfer",1,'1abc34fd',{name => 'Server 1', target => 'john@doe.com'});
  
  $self->render( json => $user_data);
}

sub encryption {
  my $self = shift;

  my $unloq = new UnloqApi(key => $key, secret => $secret);
  
  my $user_data = $unloq->encryption(1);
  
  $self->render( json => $user_data);
}

sub login {
  my $self = shift;

  my $unloq = new UnloqApi(key => $key, secret => $secret);
  
  my $user_data = $unloq->login('john@doe.com');
  
  $self->render( json => $user_data);
  
}

1;
