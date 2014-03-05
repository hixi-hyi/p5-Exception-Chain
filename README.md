# NAME

Exception::Chain - It's chained exception module

# SYNOPSIS

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

# DESCRIPTION

Exception::Chain is chained exception module

# METHODS

## throw(%info)
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

## rethrow(%info)
store tag ($info{tag}) and add message ($info{message});

## to\_string
return chained log.



## match(@tags)
matching stored tag

# LICENSE

Copyright (C) Hiroyoshi Houchi.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

Hiroyoshi Houchi <git@hixi-hyi.com>
