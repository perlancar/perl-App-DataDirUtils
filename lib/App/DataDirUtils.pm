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
        summary => 'Locations to find datadirs',
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
        skip_git => {
            summary => 'Do not recurse into .git directory',
            schema => 'bool*',
            default => 1,
        },
    },
    examples => [
        {
            summary => 'How many datadirs are here?',
            src => '[[prog]] . | wc -l',
            src_plang => 'bash',
            test => 0,
            'x.doc.show_result' => 0,
        },
        {
            summary => 'List all datadirs in all my external drives (show name as well as path)',
            src => '[[prog]] /media/budi /media/ujang -l',
            src_plang => 'bash',
            test => 0,
            'x.doc.show_result' => 0,
        },
        {
            summary => 'Backup all my datadirs to Google Drive',
            src => q{[[prog]] /media/budi /media/ujang -l | td map '"rclone copy -v -v $_->{abs_path} mygdrive:/backup/$_->{name}"' | bash},
            src_plang => 'bash',
            test => 0,
            'x.doc.show_result' => 0,
        },
    ],
};
sub list_datadirs {
    require Cwd;
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
                    #log_trace "TMP: dir=%s", $File::Find::dir;
                    my $abs_path = Cwd::getcwd();
                    defined $abs_path or do {
                        log_fatal "Cant getcwd() in %s: %s", $File::Find::dir, $!;
                        die;
                    };
                    log_trace "%s is a datadir", $abs_path;
                    push @rows, {
                        name => File::Basename::basename($abs_path),
                        path => $File::Find::dir,
                        abs_path => $abs_path,
                    };
                    return ();
                }
                log_trace "Recursing into $File::Find::dir ...";
                if ($args{skip_git}) {
                    @_ = grep { $_ ne '.git' } @_;
                }
                return @_;
            },
            wanted => sub {
            },
        },
        @prefixes,
    );

    unless ($args{detail}) {
        @rows = map { $_->{abs_path} } @rows;
    }

    [200, "OK", \@rows, {'table.fields'=>[qw/name path abs_path/]}];
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


=head1 FAQ

=head2 Why datadir?

With tagged directories, you can put them in various places and not just on a
single parent directory. For example:

 media/
   2020/
     media-2020a/ -> a datadir
     media-2020b/ -> a datadir
   2021/
     media-2021a/ -> a datadir
   etc/
     foo -> a datadir
     others/
       bar/ -> a datadir

As an alternative, you can also create symlinks:

 all-media/
   media-2020a -> symlink to ../media/2020/media-2020a
   media-2020b -> symlink to ../media/2020/media-2020b
   media-2021a -> symlink to ../media/2021/media-2021a
   media-2021b -> symlink to ../media/2021/media-2021b
   foo -> symlink to ../media/etc/foo
   bar -> symlink to ../media/etc/others/bar
