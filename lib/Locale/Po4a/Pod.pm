# Locale::Po4a::Pod -- Convert POD data to PO file, for translation.
# $Id: Pod.pm,v 1.9 2004-07-19 20:32:43 mquinson-guest Exp $
#
# Copyright 2002 by Martin Quinson <Martin.Quinson@ens-lyon.fr>
#
# This program is free software; you may redistribute it and/or modify it
# under the terms of GPL (see COPYING).
#
# This module converts POD to PO file, so that it becomes possible to 
# translate POD formated documentation. See gettext documentation for
# more info about PO files.

############################################################################
# Modules and declarations
############################################################################

use Pod::Parser;
use Locale::Po4a::TransTractor qw(process new);

package Locale::Po4a::Pod;

use 5.006;
use strict;
use warnings;

require Exporter;

use vars qw($VERSION @ISA);
$VERSION=$Locale::Po4a::TransTractor::VERSION;
@ISA = qw(Locale::Po4a::TransTractor Pod::Parser);

sub initialize {}

sub command {
    my ($self, $command, $paragraph, $line_num) = @_;
#    print STDOUT "cmd: '$command' '$paragraph' at $line_num\n";
    if ($command eq 'back'
	|| $command eq 'cut'
	|| $command eq 'pod') {
	$self->pushline("=$command\n\n");
    } elsif ($command eq 'over') {
	$self->pushline("=$command $paragraph".(length($paragraph)?"":"\n\n"));
    } else {
	$paragraph=$self->translate($paragraph,
				    $self->input_file().":$line_num",
				    "=$command",
				    "wrap"=>1);
	$self->pushline("=$command $paragraph\n");
    }
}

sub verbatim {
    my ($self, $paragraph, $line_num) = @_;
#    print "verb: '$paragraph' at $line_num\n";

    if ($paragraph eq "\n") {
	$self->pushline("$paragraph\n");
	return;
    }
    $paragraph=$self->translate($paragraph,
				$self->input_file().":$line_num",
				"verbatim");
    $paragraph =~ s/\n$//m;
    $self->pushline("$paragraph\n");
}

sub textblock {
    my ($self, $paragraph, $line_num) = @_;
#    print "text: '$paragraph' at $line_num\n";

    # Fix a pretty damned bug. 
    # Podlators don't wrap explicitelly the text, and groff won't seem to
    #  wrap any line begining with a space. So, we have to consider as
    #  verbatim not only the paragraphs whose first line is indented, but
    #  the paragraph containing an indented line.
    # That way, we'll declare more paragraphs as verbatim than needed, but
    #  that's harmless (only less confortable for translators).

    if ($paragraph eq "\n") {
	$self->pushline("$paragraph\n");
	return;
    }
    if ($paragraph =~ m/^[ \t]/m) {
	$self->verbatim($paragraph, $line_num) ;
	return;
    }

    $paragraph=$self->translate($paragraph,
				$self->input_file().":$line_num",
				'textblock',
				"wrap"=>1);
    $paragraph=~ s/ +\n/\n/gm;
    $self->pushline("$paragraph\n");
}

sub end_pod {}

sub read {
    my ($self,$filename)=@_;

    push @{$self->{DOCPOD}{infile}}, $filename;
    $self->Locale::Po4a::TransTractor::read($filename);
}

sub parse {
    my $self=shift;
    map {$self->parse_from_file($_)} @{$self->{DOCPOD}{infile}};
}

sub docheader {
    return <<EOT;

        *****************************************************
        *           GENERATED FILE, DO NOT EDIT             * 
        * THIS IS NO SOURCE FILE, BUT RESULT OF COMPILATION *
        *****************************************************

This file was generated by po4a(7) version $VERSION. Do not store
it (in cvs, for example), but store the po file used as source file by
pod-translate. 

In fact, consider this as a binary, and the po file as a regular .c file:
If the po get lost, keeping this translation up-to-date will be harder.

EOT
}
1;

##############################################################################
# Module return value and documentation
##############################################################################

1;
__END__

=head1 NAME

Locale::Po4a::Pod - Convert POD data from/to PO files

=head1 SYNOPSIS

    use Locale::Po4a::Pod;
    my $parser = Locale::Po4a::Pod->new (sentence => 0, width => 78);

    # Read POD from STDIN and write to STDOUT.
    $parser->parse_from_filehandle;

    # Read POD from file.pod and write to file.txt.
    $parser->parse_from_file ('file.pod', 'file.txt');

=head1 DESCRIPTION

Locale::Po4a::Pod is a module to help the translation of documentation in
the POD format (the preferred language for documenting Perl) into other
[human] languages.

=head1 STATUS OF THIS MODULE

I think that this module is rock stable, and there is only one known bug:

I have another problem with /usr/lib/perl5/Tk/MainWindow.pod (and some other
pages, see below) which contains:

  CE<lt>" #n"E<gt>

Lake of luck, in the po4a version, this was splited on the space by the
wrapping. As result, in the original version, the man contain 

 " #n"

and mine contain

 "" #n""
 
which is logic since C<blabla> is rewritten "blabla"

Complete list of pages having this problem on my box (from 564 pages ; note
that it depend on the choosen wrapping colon):
/usr/lib/perl5/Tk/MainWindow.pod
/usr/share/perl/5.8.0/overload.pod
/usr/share/perl/5.8.0/pod/perlapi.pod
/usr/share/perl/5.8.0/pod/perldelta.pod
/usr/share/perl/5.8.0/pod/perlfaq5.pod
/usr/share/perl/5.8.0/pod/perlpod.pod
/usr/share/perl/5.8.0/pod/perlre.pod
/usr/share/perl/5.8.0/pod/perlretut.pod



=head1 INTERNALS

As a derived class from Pod::Parser, Locale::Po4a::Pod supports the same
methods and interfaces.  See L<Pod::Parser> for all the details; briefly,
one creates a new parser with C<< Locale::Po4a::Pod->new() >> and then
calls either parse_from_filehandle() or parse_from_file().

new() can take options, in the form of key/value pairs, that control the
behavior of the parser.  The recognized options common to all Pod:;Parser
children are:

=over 4

=item alt

If set to a true value, selects an alternate output format that, among other
things, uses a different heading style and marks C<=item> entries with a
colon in the left margin.  Defaults to false.

=item code

If set to a true value, the non-POD parts of the input file will be included
in the output.  Useful for viewing code documented with POD blocks with the
POD rendered and the code left intact.

=item indent

The number of spaces to indent regular text, and the default indentation for
C<=over> blocks.  Defaults to 4.

=item loose

If set to a true value, a blank line is printed after a C<=head1> heading.
If set to false (the default), no blank line is printed after C<=head1>,
although one is still printed after C<=head2>.  This is the default because
it's the expected formatting for manual pages; if you're formatting
arbitrary text documents, setting this to true may result in more pleasing
output.

=item quotes

Sets the quote marks used to surround CE<lt>> text.  If the value is a
single character, it is used as both the left and right quote; if it is two
characters, the first character is used as the left quote and the second as
the right quoted; and if it is four characters, the first two are used as
the left quote and the second two as the right quote.

This may also be set to the special value C<none>, in which case no quote
marks are added around CE<lt>> text.

=item sentence

If set to a true value, Locale::Po4a::Pod will assume that each sentence
ends in two spaces, and will try to preserve that spacing.  If set to
false, all consecutive whitespace in non-verbatim paragraphs is compressed
into a single space.  Defaults to true.

=item width

The column at which to wrap text on the right-hand side.  Defaults to 76.

=back

The options specific to Locale::Po4a::Pod are:

=over 4

=item pomode

In fact, this parser can work in to modes. When pomode=write, it reads a
pod file, and extract the string which should be translated to a pot
file. When pomode=read (the default), it reads a pod file and write a
similar pod file, but translating all strings on the way (the translation
is read from the po file).

=item dontwrite

if set, no file is written at the end (if you want to manipulate the
extracted po file in memory, for example).

=back

=head1 SEE ALSO

L<Pod::Parser>, L<po4a(7)>, L<Locale::Po4a::TransTranctor(3pm)>,
L<Locale::Po4a::Man(3pm)>,

=head1 AUTHORS

 Denis Barbier <barbier@linuxfr.org>
 Martin Quinson <martin.quinson@tuxfamily.org>

=head1 COPYRIGHT AND LICENSE

Copyright 2002 by SPI, inc.

This program is free software; you may redistribute it and/or modify it
under the terms of GPL (see COPYING file).

=cut
