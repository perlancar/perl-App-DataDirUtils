package App::DataDirUtils;

use 5.010001;
use strict;
use warnings;
use Log::ger;

#use File::chdir;

# AUTHORITY
# DATE
# DIST
# VERSION

our %SPEC;

$SPEC{':package'} = {
    v => 1.1,
    summary => 'CLI utilities related to datadirs',
};

our %argspecs_common = (
    prefixes => {
        summary => 'Changes file',
        schema => ['array*', of=>'dirname*'],
        req => 1,
        pos => 0,
        slurpy => 1,
        description => <<'_',

Directory name(s) to search for "datadirs", i.e. directories which have
`.tag-datadir` file in its root.

_
    },
);

$SPEC{list_datadirs} = {
    v => 1.1,
    summary => 'Search datadirs recursively in a list of directory names',
    description => <<'_',

Note: when a datadir is found, its contents are no longer recursed to search for
other datadirs.

_
    args => {
        %argspecs_common,
        detail => {
            schema => 'bool*',
            cmdline_aliases => {l=>{}},
        },
    },
};
sub list_datadirs {
    require File::Basename;
    require File::Find;

    my %args = @_;
    @{ $args{prefixes} }
        or return [400, "Please specify one or more directories in 'prefixes'"];

    my @prefixes;
    for my $prefix (@{ $args{prefixes} }) {
        (-d $prefix) or do {
            log_error "Not a directory '$prefix', skip searching datadirs in this directory";
            next;
        };
        push @prefixes, $prefix;
    }

    my @rows;
    File::Find::find(
        {
            preprocess => sub {
                if (-f ".tag-datadir") {
                    push @rows, {
                        name => File::Basename::basename(File::Find::dir),
                        path => $File::Find::dir,
                    };
                    return ();
                }
                return @_;
            },
            wanted => sub {
            },
        },
        @prefixes,
    );

    unless ($args{detail}) {
        @rows = map { $_->{name} } @rows;
    }

    [200, "OK", \@rows];
}

1;
# ABSTRACT:

=head1 SYNOPSIS

See CLIs included in this distribution.


=head1 DESCRIPTION

This distribution includes several utilities related to datadirs:

#INSERT_EXECS_LIST

A "datadir" is a directory which has a (usually empty) file called
F<.tag-datadir>. A datadir usually does not contain other datadirs.

You can backup, rsync, or do whatever you like with a datadir, just like a
normal filesystem directory. The utilities provided in this distribution help
you handle datadirs.
