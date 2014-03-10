package Exception::Chain;
use 5.008005;
use strict;
use warnings;

use Class::Accessor::Lite (
    ro => [qw/ id message /],
);
use Time::Piece qw(localtime);
use Time::HiRes qw(gettimeofday tv_interval);

our $VERSION = "0.01";

# class method
sub new {
    my ($class, %args) = @_;

    my $self = bless {
        tags    => {},
        stack   => [],
        message => undef,
    }, $class;
}

sub _build_arg {
    my ($class, @info) = @_;
    chomp $_ for @info;

    if (scalar @info == 0) {
        return { };
    }
    elsif (scalar @info == 1) {
        if ($class->_is_my_instance($info[0])) {
            return { error => $info[0] };
        }
        else {
            return { message => $info[0] };
        }
    }
    else {
        my %data = @info;
        my $ret = {};

        if ($data{tag}) {
            $ret->{tag} = $data{tag};
        }
        if ($data{message}) {
            $ret->{message} = $data{message};
        }
        if ($data{error}) {
            $ret->{error} = $data{error};
        }
        return $ret;
    }
}

sub _is_my_instance {
    my ($class, $instance) = @_;
    ($instance && ref $instance eq 'Exception::Chain') ? 1: 0;
}

# instance method

sub throw {
    my ($class, @args) = @_;
    my $builded_args = $class->_build_arg(@args);
    my $self;
    if (not defined $builded_args->{error}) {
        $self = $class->new;
        $self->{message} = $builded_args->{message};
    }
    elsif ($class->_is_my_instance($builded_args->{error})) {
        $self = delete $builded_args->{error};
    }
    else {
        $self = $class->new;
        push @{$self->{stack}}, $builded_args->{error};
        $self->rethrow($builded_args->{message});
    }
    $self->logging($builded_args);
    die $self;
}

sub rethrow {
    my ($self, @args) = @_;
    $self->logging($self->_build_arg(@args));
    die $self;
}

sub to_string {
    my $self = shift;
    join( ' ', @{$self->{stack}} );
}

sub match {
    my ($self, @tags) = @_;
    return scalar grep { defined $self->{tags}{$_} } @tags;
}

sub first_message {
    my $self = shift;
    return $self->{message};
}

sub logging {
    my ($self, $args) = @_;

    my $i = 0;
    my ($pkg, $file, $line);
    while (my @caller = caller(++$i)) {
        unless ($caller[0] =~ /^Exception::Chain/) {
            ($pkg, $file, $line) = @caller;
            last;
        }
    }

    if (%{$args}) {
        if (my $tags = $args->{tag}) {
            $tags = [$tags] unless ref $tags;
            for my $tag (@$tags) {
                $self->{tags}{$tag} = 1;
            }
        }
        if (my $message = $args->{message}) {
            push @{$self->{stack}}, "$message at $file line $line.";
        }
    }
    else {
        push @{$self->{stack}}, "at $file line $line.";
    }
}


1;
__END__

=encoding utf-8

=head1 NAME

Exception::Chain - It's chained exception module

=head1 SYNOPSIS

    use Exception::Chain;

    eval {
        process;
    };
    if (my $e = $@) {
        if ($e->match('critical')) {
            logging($e->to_string);
            # can not connect server at get_user line [A]. dbname=user is connection failed at get_user line [B]. request_id : [X] at process line [C].
        }
        if ($e->match('critical', 'internal server error')) { # or
            send_email($e->to_string);
        }
        if ($e->match('connection failed')) {
            retry;
        }
    }

    sub get_user {
        eval {
            # die 'can not connect server',
        };
        if (my $e = $@) {
            Exception::Chain->throw(
                tag     => ['connection failed', 'critical'],
                message => 'dbname=user is connection failed',
                error   => $e,
            );
        }
    }
    sub process {
        eval {
            get_user();
        };
        if (my $e = $@) {
            Exception::Chain->throw(
                tag     => 'internal server error',
                message => sprintf('request_id : %s', $params->{request_id}),
                error   => $e,
            );
            # $e->rethrow(
            #    tag     => 'internal server error',
            #    message => sprintf('request_id : %s', $params->{request_id}),
            # );
        }
    }

=head1 DESCRIPTION

Exception::Chain is chained exception module

=head1 METHODS

=head2 throw(%info)
store tag ($info{tag}) and store message ($info{message}).

    throw($e); # Exception::Chain instance or message
    throw(
        tag     => 'critical',
        message => 'connection failed',
    )
    throw(
        tag     => ['critical', 'database error'],
        message => 'connection failed',
    )
    throw(
        tag     => ['critical', 'database error'],
        message => 'connection failed',
        error   => $@
    )

=head2 rethrow(%info)
store tag ($info{tag}) and add message ($info{message});

=head2 to_string
return chained log.


=head2 match(@tags)
matching stored tag

=head1 LICENSE

Copyright (C) Hiroyoshi Houchi.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Hiroyoshi Houchi E<lt>git@hixi-hyi.comE<gt>

=cut

