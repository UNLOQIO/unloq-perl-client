package UnloqResults;

use strict;
use warnings;

use Moose;

has error => (
    is => 'rw',
    isa => 'Value',
    default => 1
);

has type => (
    is => 'rw',
    isa => 'Str'
);

has code => (
    is => 'rw',
    isa => 'Any'
);

has message => (
    is => 'rw',
    isa => 'Any'
);

has data => (
    is => 'rw',
    isa => 'Any'
);

sub set_error {
    my $self = shift;
    my $code = shift || "SERVER_ERROR";
    my $message = shift || "An unexpected error occurred. Please try again later.";
    my $data = shift;
    
    $self->error(1);
    $self->type('error');
    $self->code($code);
    $self->message($message);
}

sub set_success {
    my $self = shift;
    my $data = shift;
    
    $self->error(0);
    $self->type('success');
    $self->data($data);
}

sub to_hash {
    my $self = shift;
    
    my $data = $self->error ? {type => $self->type, code => $self->code, message => $self->message}
                            : {type => $self->type, data => $self->data};
    
    return $data;
}

1;