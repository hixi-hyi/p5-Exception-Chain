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

sub new {
    my ($class, %args) = @_;

    my $self = bless {
        tags    => {},
        stack   => [],
    }, $class;
}

sub throw {
    my ($class, @args) = @_;
    my $self = $class->new;
    $self->logging($self->_build_arg(@args));
    die $self;
}

sub rethrow {
    my ($self, @args) = @_;
    $self->logging($self->_build_arg(@args));
    die $self;
}

sub to_string {
    my $self = shift;
    join( ', ', @{$self->{stack}} );
}

sub match {
    my ($self, @tags) = @_;
    return scalar grep { defined $self->{tags}{$_} } @tags;
}

sub logging {
    my ($self, $args) = @_;

    my $i = 0;
    my ($pkg, $file, $line);
    while (my @caller = caller(++$i)) {
        unless ($caller[0] =~ /^Exception::Chain/) {
            ($pkg, $file, $line) = @caller;
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
            push @{$self->{stack}}, "$message at $file line $line";
        }
    }
    else {
        push @{$self->{stack}}, "at $file line $line";
    }
}

sub _build_arg {
    my ($self, @info) = @_;

    if (scalar @info == 0) {
        return { };
    }
    elsif (scalar @info == 1) {
        return { message => $info[0] };
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
        return $ret;
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
            # dbname=user is connection failed at get_user line x, request_id : y, at process line z
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
            # db connection,,,,,
        };
        if (my $e = $@) {
            Exception::Chain->throw(
                tag     => ['connection failed', 'critical'],
                message => 'dbname=user is connection failed'
            );
        }
    }
    sub process {
        eval {
            get_user();
        };
        if (my $e = $@) {
            $e->rethrow(
                tag     => 'internal server error',
                message => sprintf('request_id : %s', $params->{request_id}),
            );
        }
    }

=head1 DESCRIPTION

Exception::Chain is chained exception module

=head1 METHODS

=head2 throw(%info)
store tag ($info{tag}) and store message ($info{message}).

    throw('message');
    throw(
        tag     => 'critical',
        message => 'connection failed',
    )
    throw(
        tag     => ['critical', 'database error'],
        message => 'connection failed',
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

