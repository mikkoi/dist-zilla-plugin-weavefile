## no critic (ControlStructures::ProhibitPostfixControls)
package Dist::Zilla::Plugin::WeaveFile;

use strict;
use warnings;
use 5.010;

# ABSTRACT: Create project files by weaving together POD, metadata, and snippets

our $VERSION = '0.001';

use Moose;
with 'Dist::Zilla::Role::Plugin';
use namespace::autoclean;

=pod

=encoding utf8

=for Pod::Coverage mvp_multivalue_args register_prereqs

=for stopwords Dist dzil

=head1 STATUS

Dist-Zilla-Plugin-WeaveFile is currently being developed so changes in the
API are possible, though not likely.

=head1 SYNOPSIS

=for test_synopsis BEGIN { die "SKIP: skip this pod!\n"; }

In your F<dist.ini>:

    ; Uses default config file .weavefilerc
    [WeaveFile / README.md]

    ; Uses a custom config file and specifies file explicitly
    [WeaveFile]
    config = install-weave.yaml
    file = INSTALL

    [Test::WeaveFile]

Then run:

    dzil weave            # generate all configured files
    dzil weave README.md  # generate one file

=head1 DESCRIPTION

Dist-Zilla-Plugin-WeaveFile is a L<Dist::Zilla> plugin, command, and test
plugin for creating project files by weaving together POD documentation,
distribution metadata, and text snippets using templates.

=head1 MOTIVATION

It used to be so that a B<repository> was only a place of work
and the B<distribution> was the actual result of that work.
Only the contents of the distribution mattered. People would
read the files F<README> and F<INSTALL> from the distribution
after having downloaded it.

Not so anymore. Today the repository is out in the open in
L<GitHub|https://www.github.com>,
L<GitLab|https://www.gitlab.com>,
L<Codeberg|https://codeberg.org/>
or other shared hosting site.
On the other hand, the documentation in the distribution is often
discarded as distribution packages are rarely downloaded manually
but rather via a package manager which installs them automatically.

Publicly viewable repository has in fact become much more
than just a place of work. It is also an advertisement
for the project and of the community behind it, if there is
more than one author or contributor.

When a potential user first finds the project repository,
the hosting site commonly presents him with the project F<README>
file. That makes the readme file in fact the B<welcome page>
to the project. Its purpose now is now changed from a purely
informational introduction to an advertisement which
competes for user's attention with bright colors,
animated pictures, videos and exciting diagrams, shapes
and "bumber stickers".

But under all the exciting cover it must also remain
true to its nature: present the project
as precisely as possible and stay up to date with
its development.

F<README> might also not be the only file which needs
to be kept up to date because it is accessed in the (public) repository.
Other potential files can include
F<INSTALL>, F<Changes> and F<CODEOWNERS>.

Many files therefore contain text which
must be updated at least at the time of release:
version numbers, API documentation, examples,
file lists.

It is difficult to keep these files in sync
with the code. Just like documentation, which fact
every programmer knows. This L<Dist::Zilla>
plugin will prevent the files from falling out of sync
because their content is tested continuously.

There are other ways to do this, for instance
L<Dist::Zilla::Plugin::CopyFilesFromBuild>.
It is my philosphy that nothing in the repository
is changed I<behind programmer's back>.
It can also be dangerous to the programmer
if he is not a frequent Git committer.
Failed local tests are much safer.
And when the test fails, it is easy
to run C<dzil weave> to update the files.


=head1 USAGE

Define which files to generate in F<dist.ini>, write the file templates in
a YAML config file (default config file name F<.weavefilerc>),
and use C<dzil weave> to generate or update the files.

The config file uses L<Template::Toolkit|Template> syntax with access to:

=over 4

=item *

B<dist> - distribution metadata (name, abstract, version, author, authors)

=item *

B<snippets> - reusable text fragments defined in the config

=item *

B<pod(source, section)> - extracts a POD section from a Perl module or
script and converts it to Markdown

=back

=head2 Config file format

The config file (YAML) has two sections:

    ---
    snippets:
        badges: |
            [![CPAN](https://img.shields.io/cpan/v/My-Dist)](https://metacpan.org/dist/My-Dist)
        license: |
            This software is free software.

    files:
        "README.md": |
            [% snippets.badges %]
            # [% dist.name %]
            [% dist.abstract %]
            [% pod("My::Module", "SYNOPSIS") %]
            [% pod("My::Module", "DESCRIPTION") %]
            [% snippets.license %]

=head1 ATTRIBUTES

=head2 config

Path to the YAML config file, relative to the project root.
Defaults to F<.weavefilerc>.

=cut

has config => (
    is      => 'ro',
    isa     => 'Str',
    default => '.weavefilerc',
);

=head2 file

Output filename. Defaults to the plugin moniker (the part after C</>
in C<[WeaveFile / README.md]>).

=cut

has file => (
    is      => 'ro',
    isa     => 'Str',
    lazy    => 1,
    default => sub { $_[0]->plugin_name },
);

sub mvp_multivalue_args { return () }

sub register_prereqs {
    my $self = shift;
    $self->zilla->register_prereqs(
        { type => 'requires', phase => 'develop' },
        'Dist::Zilla::App::Command::weave' => 0,
    );
    return;
}

around BUILDARGS => sub {
    my ($orig, $class, @arg) = @_;
    my $args  = $class->$orig(@arg);
    my %copy  = %{$args};
    my $zilla = delete $copy{zilla};
    my $name  = delete $copy{plugin_name};
    my %known;
    for my $key (qw( config file )) {
        $known{$key} = delete $copy{$key} if exists $copy{$key};
    }
    if (%copy) {
        $zilla->log_fatal([
            'Unknown configuration option(s) in %s: %s',
            __PACKAGE__ . ' / ' . $name,
            join(q{,}, keys %copy),
        ]);
    }
    return {
        zilla       => $zilla,
        plugin_name => $name,
        %known,
    };
};

__PACKAGE__->meta->make_immutable;

=pod

=head1 SEE ALSO

=over 8

=item L<Dist::Zilla::Plugin::CopyFilesFromBuild>

=item L<Dist::Zilla::Plugin::CopyReadmeFromBuild>

=back

=cut
1;

__END__
