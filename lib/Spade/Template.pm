package Spade::Template;

use strict;
use warnings;
use Marpa::R2;
use Data::Dumper::Simple;

use feature ':5.10';

my %symbol_for_char = (
    '{' => 'OPEN_CURLY',    '}' => 'CLOSE_CURLY',
    '(' => 'OPEN_PAREN',    ')' => 'CLOSE_PAREN',
    '[' => 'OPEN_BRACKET',  ']' => 'CLOSE_BRACKET',
    ';' => 'SEMICOLON',     ':' => 'COLON',
    ',' => 'COMMA',         '.' => 'DOT',
    '*' => 'SPLASH',        '#' => 'HASH',
    '/' => 'SLASH',         '>' => 'GT',
    '+' => 'PLUS',
);



sub new {
  my ( $class, $args ) = @_;
  my $this = {};
  bless( $this, $class );
  return $this;

}

sub process {
  my ( $this, $text ) = @_;
  my $output = $text;
  #
  # Phase 1 -- sequentially scan terminals
  #
  my @tokens;
  my $t = sub {
    push @tokens, [ @_ ];
    # must return empty string, because we might be inside a replacement
    return '';
  };

  while (length($text)) {
    
    no warnings;
#    $text =~ s{\A \s* // .*? ^}{}xms and next;
#    $text =~ s{\A \s* (/\* .*? \*/) \s*}{ $t->(COMMENT => $1 ) }exms and next;
#    $text =~ s{\A \s* \@([a-z]+) \s*}{ $t->("AT_\U$1") }exms and next;
#    $text =~ s{\A \s* (['"]) ((?:[^\\\1] | \\.)*?) \1 \s*}{ $t->(STRING => $2) }exms and next;
#    $text =~ s{\A \s+ }{ $t->('SPACE') }exms and next;
    $text =~ s{\A \s* (-?[_a-zA-Z][-_a-zA-Z0-9]*)}{$t->(TAG => $1)}exms and next;
#    $text =~ s{\A \s* (\.\d+ | \d+ (?:\.\d*)?) \s* (%|em|ex|px|cm|mm|pt|pc|deg|rad|grad|ms|s|hz|khz)? \s*}{ $t->(NUMBER => "$1$2") }exms and next;
    
    my $char = substr($text,0,1,'');
    if (exists($symbol_for_char{$char})) {
        $t->($symbol_for_char{$char});
    } else {
        $t->(CHAR => $char);
    }
  } 

  print Dumper( @tokens );

  my $grammar = $this->get_grammar();

  #
  # phase 3 -- parse our tokens
  #
  my $rec = Marpa::R2::Recognizer->new( { grammar => $grammar } );
  foreach my $token (@tokens) {
    if ($token->[0] eq 'COMMENT') {
        # process comments in a different way
    } elsif (defined $rec->read( @$token )) {
        say "reading Token: @$token";
    } else {
        die "Error reading Token: @$token";
    };
  } 



  return $rec->value;
}

sub get_grammar {
  my ( $this ) = @_;


  my $grammar = Marpa::R2::Grammar->new(
    { start     => 'expression',
      actions   => 'Spade::Template',
      default_action  => 'do_default', 
      terminals => [qw(
        OPEN_CURLY CLOSE_CURLY OPEN_PAREN CLOSE_PAREN OPEN_BRACKET CLOSE_BRACKET
        SPACE SEMICOLON COLON COMMA SPLASH DOT HASH ATTR_CMP GT PLUS
        STRING IDENT HEXCOLOR NUMBER
        AT_CHARSET AT_IMPORT AT_MEDIA AT_PAGE IMPORTANT
      )], 
      rules => [
        { lhs => 'expression', rhs => [ qw(TAG) ], action => "do_tag" },

          
      ]
    
     }
  );
  $grammar->precompute();

  return $grammar;
  

}

sub do_tag {
  my ($this, $tag ) = @_;
  return "<$tag></$tag>";
    
 
}

sub do_default {
    say Dumper(@_);
    return;
}
sub function_call {
    say Data::Dumper->Dump([ [@_] ],[ 'Function_Call' ]);
    return "$_[1]($_[3])";
}

sub expression {
    say Data::Dumper->Dump([ [@_] ],[ 'Expression' ]);
    return $_[1];
}

1;

