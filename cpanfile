requires 'perl', '5.008001';
requires 'Class::Accessor::Lite';
requires 'Time::Piece';
requires 'Time::HiRes';

on 'test' => sub {
    requires 'Test::More', '0.98';
};

