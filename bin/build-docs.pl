#!/usr/bin/env perl

use strict;
use warnings;
use feature qw(say);
use experimental qw(signatures);

use File::Spec;
use File::Temp;
use JSON qw(decode_json encode_json);
use POSIX qw(:errno_h);

sub read_text($filename) {
    use autodie;

    open my $fh, '<', $filename;
    my $text = do { local $/; <$fh> };
    close $fh;
    return $text;
}

sub write_text($filename, $contents) {
    use autodie;

    open my $fh, '>', $filename;
    print {$fh} $contents;
    close $fh;
}

sub get_cache_dir {
    if($^O eq 'MSWin32') {
        return unless $ENV{'LOCALAPPDATA'};

        return File::Spec->catdir($ENV{'LOCALAPPDATA'}, 'elm-docs-offline');
    } elsif($^O eq 'darwin') {
        return unless $ENV{'HOME'};
        return File::Spec->catdir($ENV{'HOME'}, 'Library', 'Caches', 'elm-docs-offline');
    } else {
        if($ENV{'XDG_CACHE_HOME'}) {
            return File::Spec->catdir($ENV{'XDG_CACHE_HOME'}, 'elm-docs-offline');
        } else {
            return unless $ENV{'HOME'};
            return File::Spec->catdir($ENV{'HOME'}, '.cache', 'elm-docs-offline');
        }
    }
}

sub make_path($path) {
    my ( $volume, $dirs, $filename ) = File::Spec->splitpath($path);
    my @dirs = File::Spec->splitdir($dirs);

    for my $i (0..$#dirs) {
        my $ancestor = File::Spec->catpath($volume, File::Spec->catdir(@dirs[0..$i]), '');
        if(!mkdir($ancestor) && $! != EEXIST) {
            die "mkdir $ancestor failed; $!";
        }
    }
}

sub make_cacher($cache_dir) {
    return ( sub {}, sub {} ) unless $cache_dir;

    my $get = sub($key) {
        my $path = File::Spec->catfile($cache_dir, $key);

        my $fh;
        if(!open($fh, '<', $path)) {
            return;
        }
        my $contents = do {
            local $/;
            <$fh>
        };
        close $fh;
        return $contents;
    };

    my $set = sub($key, $value) {
        my $path = File::Spec->catfile($cache_dir, $key);
        make_path($path);

        my $fh;
        if(!open($fh, '>', $path)) {
            warn "$path: $!";
            return;
        }
        print {$fh} $value;
        close $fh;
    };

    return ( $get, $set );
}

sub generate_docs($package, $version) {
    use autodie;

    my $docs_file = File::Temp->new;

    my $pid = fork;

    if($pid) {
        waitpid $pid, 0;

        local $/;
        my $docs_json = <$docs_file>;
        close $docs_file;
        return decode_json($docs_json);
    } else {
        chdir "elm-stuff/packages/$package/$version";
        if($package eq 'elm-lang/core') { # XXX not ideal, but core is special
            mkdir 'elm-stuff' unless -d 'elm-stuff';
            write_text('elm-stuff/exact-dependencies.json', '{}');
        }
        open STDOUT, '>&', \*STDERR;
        exec 'elm-make', '--yes', '--docs', $docs_file->filename;
    }
}

my %symbols;
sub emit {
    my %attrs = @_;

    my $name = $attrs{'name'};

    if($attrs{'module'}) {
        $name = $attrs{'module'} . '.' . $name;
    }

    $symbols{$name} = \%attrs;
}

sub flush {
    print encode_json(\%symbols);
}

my ( $cache_get, $cache_set ) = make_cacher(get_cache_dir());
my $dependencies = decode_json(read_text 'elm-stuff/exact-dependencies.json');

foreach my $package (sort keys %$dependencies) {
    my $version = $dependencies->{$package};

    my $docs = $cache_get->("$package-$version");
    if($docs) {
        $docs = decode_json($docs);
    } else {
        $docs = generate_docs($package, $version);
        $cache_set->("$package-$version", encode_json($docs));
    }

    foreach my $module (@$docs) {
        emit(
            category => 'module',
            name     => $module->{'name'},
            comment  => $module->{'comment'},
        );
        if(my $values = $module->{'values'}) {
            # XXX what about constants?
            foreach my $value (@$values) {
                emit(
                    category => 'function',
                    name     => $value->{'name'},
                    module   => $module->{'name'},
                    comment  => $value->{'comment'},
                    type     => $value->{'type'},
                );
            }
        }
        if(my $types = $module->{'types'}) {
            # XXX args, cases
            foreach my $type (@$types) {
                emit(
                    category => 'type',
                    name     => $type->{'name'},
                    module   => $module->{'name'},
                    comment  => $type->{'comment'},
                );
            }
        }
        if(my $aliases = $module->{'aliases'}) {
            foreach my $alias (@$aliases) {
                emit(
                    category => 'alias',
                    name     => $alias->{'name'},
                    module   => $module->{'name'},
                    comment  => $alias->{'name'},
                    type     => $alias->{'type'},
                );
            }
        }
    }
}

flush;
