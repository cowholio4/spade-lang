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
    '+' => 'PLUS',          '=' => 'EQUALS'
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
    print "text\t$text\n";
#    $text =~ s{\A \s* // .*? ^}{}xms and next;
#    $text =~ s{\A \s* (/\* .*? \*/) \s*}{ $t->(COMMENT => $1 ) }exms and next;
#    $text =~ s{\A \s* \@([a-z]+) \s*}{ $t->("AT_\U$1") }exms and next;
#    $text =~ s{\A \s* (['"]) ((?:[^\\\1] | \\.)*?) \1 \s*}{ $t->(STRING => $2) }exms and next;
    $text =~ s{\A \s+ }{ $t->('SPACE') }exms and next;
    $text =~ s{\A([\w\-]+)}{$t->(TAG => $1)}exms and next;
    $text =~ s{\A"([\w\-]+)"}{$t->(TERM => $1)}exms and next;
    $text =~ s{\A'([\w\-]+)'}{$t->(TERM => $1)}exms and next;
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
    { start     => 'EXPRESSION',
      actions   => 'Spade::Template',
      default_action  => 'do_default', 
      terminals => [qw(
        OPEN_CURLY CLOSE_CURLY OPEN_PAREN CLOSE_PAREN OPEN_BRACKET CLOSE_BRACKET
        SPACE SEMICOLON COLON COMMA SPLASH DOT HASH ATTR_CMP GT PLUS
        STRING IDENT HEXCOLOR NUMBER
        AT_CHARSET AT_IMPORT AT_MEDIA AT_PAGE IMPORTANT
      )], 
      rules => [
        { lhs => 'EXPRESSION', rhs => [ qw(ELEMENT)], action => "do_combine_tag"  },
        { lhs => 'EXPRESSION', rhs => [ qw(ELEMENT SPACE PROPERTIES) ], action => "do_combine_tag"  },

        { lhs => 'ELEMENT', rhs => [ qw(TAG HASH TAG) ], action => "do_tag_id" },
        { lhs => 'ELEMENT', rhs => [ qw(TAG DOT TAG) ], action => "do_tag_class" },
        { lhs => 'ELEMENT', rhs => [ qw(HASH TAG) ], action => "do_implicit_tag_id" },
        { lhs => 'ELEMENT', rhs => [ qw(DOT TAG) ], action => "do_implicit_tag_class" },
        { lhs => 'ELEMENT', rhs => [ qw(TAG) ], action => "do_tag" },

        { lhs => 'PROPERTIES', rhs => [ qw(PROPERTY SPACE PROPERTIES) ], action => "append"  },
        { lhs => 'PROPERTIES', rhs => [ qw(PROPERTY) ]  },

        { lhs => 'PROPERTY', rhs => [ qw(TAG EQUALS TERM) ], action => "do_property" },

#:        { lhs => 'TAG', rhs => [ qw(STRING) ]  },
#        { lhs => 'TAG', rhs => [ qw(STRING SPECIALIZERS STRING) ], action => "do_tag" },
#        { lhs => 'SPECIALIZERS', rhs => [ qw(SPECIALIZER) ] },
#        { lhs => 'SPECIALIZER', rhs => [ qw(HASH) ] },
        
      ]
    
     }
  );
  $grammar->precompute();

  return $grammar;
  

}

sub append {
  my ($this, $lhs, $delimeter, $rhs ) = @_;

}


sub do_combine_tag {
  my ($this, $element, $delimeter, $properties ) = @_;
  $properties ||= {};
  my $tag   = $element->{tag};
  my $id    = $element->{id}    || $properties->{id};
  my $class = $element->{class} || $properties->{class};
  my $props = "";
  $props .= "id='$id' " if $id;
  $props .= "class='$class' " if $class;
  for my $key ( keys $properties ) {
    my $value = $properties->{$key};
    $props .= "$key='$value'";
  }
  $props =~ s/\s+$//;
  my $html = "<$tag";
  $html .= " " if( length $props > 0 );
  return $html . "$props></$tag>";
}

sub do_tag {
  my ($this, $tag ) = @_;
  print "do_tag\n";
  print Dumper( @_ );
  return { tag => $tag };
}
sub do_tag_id {
  my ($this, $tag, undef, $id ) = @_;
  return { id => $id, tag => $tag };
}
sub do_tag_class {
  my ($this, $tag, undef, $class ) = @_;
  return { class => $class, tag => $tag };
}
sub do_implicit_tag_class {
  my ($this, undef, $class ) = @_;
  return { class => $class, tag => "div" };
}
sub do_implicit_tag_id {
  my ($this, undef, $id ) = @_;
  return { id => $id, tag => "div" };
}

sub do_property {
  my ($this, $prop, undef, $value ) = @_;
  print "do_property\n";
  return { $prop => $value };
}



sub do_default {
  my ( $this, $value ) = @_;
  print Dumper( @_);
  return $value;
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

