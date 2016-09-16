#!/usr/bin/env perl

use autodie;
use strict;
use warnings;
use feature qw(say);
use experimental qw(signatures);

use File::Temp;
use JSON qw(decode_json encode_json);

sub read_text($filename) {
    open my $fh, '<', $filename;
    my $text = do { local $/; <$fh> };
    close $fh;
    return $text;
}

sub write_text($filename, $contents) {
    open my $fh, '>', $filename;
    print {$fh} $contents;
    close $fh;
}

sub generate_docs($package, $version) {
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

my $dependencies = decode_json(read_text 'elm-stuff/exact-dependencies.json');

foreach my $package (sort keys %$dependencies) {
    my $version = $dependencies->{$package};

    my $docs = generate_docs($package, $version);

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
