package Unloq::Controller::Authenticate;
use Mojo::Base 'Mojolicious::Controller';

use lib 'lib';
use UnloqApi;

my $key = "a17dff1acb4638b1e99c4d86c1958212997386b75ed17d6d920af1765bb705d9";
my $secret = "120si5TL9HPw9D62yyXYHCuZyikRAgqk";

sub authenticate {
  my $self = shift;

  my $unloq = new UnloqApi(key => $key, secret => $secret);
  
  my $token = $unloq->authenticate('ciocan.paul.florin@gmail.com');
  
  $self->render( json => $token);
}

sub authorize {
  my $self = shift;

  my $unloq = new UnloqApi(key => $key, secret => $secret);
  
  my $user_data = $unloq->authorize("transfer",491,'1abc34fd',{name => 'Server 1', target => 'john@doe.com'});
  
  $self->render( json => $user_data);
}

sub encryption {
  my $self = shift;

  my $unloq = new UnloqApi(key => $key, secret => $secret);
  
  my $user_data = $unloq->encryption(491);
  
  $self->render( json => $user_data);
}

sub login {
  my $self = shift;

  my $unloq = new UnloqApi(key => $key, secret => $secret);
  
  my $user_data = $unloq->login('ciocan.paul.florin@gmail.com');
  
  $self->render( json => $user_data);
  
}

1;
