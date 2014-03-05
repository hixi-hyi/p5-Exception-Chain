#!/usr/bin/env perl -w
use strict;
use Test::More;
use Test::Deep;
use Test::Exception;
use Test::Flatten;

use Exception::Chain;

subtest 'simple' => sub {
    throws_ok {
        Exception::Chain->throw(
            message => 'invalid request',
        );
    } 'Exception::Chain', 'throws ok';
    my $e = $@;
    like $e->to_string, qr{invalid request at t/simple.t line};
    note explain $e->to_string;
};

subtest 'chain message' => sub {
    throws_ok {
        eval {
            Exception::Chain->throw(
                message => 'invalid request',
            );
        };
        if (my $e = $@) {
            $e->rethrow('operation denied');
        }
    } 'Exception::Chain', 'throws ok';
    my $e = $@;
    like $e->to_string, qr{invalid request at t/simple\.t line \d+, operation denied at t/simple\.t line \d+};
    note explain $e->to_string;
};

subtest 'match single' => sub {
    throws_ok {
        Exception::Chain->throw(
            tag     => 'invalid request',
            message => 'msg is invalid parameter',
        );
    } 'Exception::Chain', 'throws ok';
    my $e = $@;
    is $e->match('invalid request'), 1, 'match exception is ok';
    is $e->match('not match'),       0, 'match exception is ok';
};

subtest 'match plural' => sub {
    my @condition = ('invalid request', 'unauthorized');
    throws_ok {
        Exception::Chain->throw(
            tag     => 'invalid request',
            message => 'msg is invalid parameter',
        );
    } 'Exception::Chain', 'throws ok';
    my $e = $@;
    is $e->match(@condition), 1, 'match exception is ok';

    throws_ok {
        Exception::Chain->throw(
            tag     => 'unauthorized',
            message => 'user_id is invalid',
        );
    } 'Exception::Chain', 'throws ok';
    $e = $@;
    is $e->match(@condition), 1, 'match exception is ok';
};

subtest 'define multi tag' => sub {
    throws_ok {
        Exception::Chain->throw(
            tag     => ['connection failed', 'crit'],
            message => 'dbname=user is connection failed',
        );
    } 'Exception::Chain', 'throws ok';
    my $e = $@;
    is $e->match('connection failed'), 1, 'match exception is ok';
    is $e->match('crit'),              1, 'match exception is ok';
};

subtest 'chain tag' => sub {
    throws_ok {
        eval {
            Exception::Chain->throw(
                tag     => 'connection failed',
                message => 'dbname=user is connection failed'
            );
        };
        if (my $e = $@) {
            $e->rethrow(tag => 'internal server error');
        }
    } 'Exception::Chain', 'throws ok';
    my $e = $@;
    is $e->match('connection failed'), 1, 'match exception is ok';
    is $e->match('internal server error'), 1, 'match exception is ok';
};

done_testing;
