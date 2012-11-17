#!/usr/bin/perl
use Test::More;

use Data::Dumper::Simple;
use Spade::Template;

my $t = Spade::Template->new();
isa_ok( $t, 'Spade::Template' );
my ( $input, $output );

$input = "";
$output = $t->process( $input );
is( $$output, "");

$input = "div";
$output = $t->process( $input );
is( $$output, "<div></div>");


$input = "span";
$output = $t->process( $input );
is( $$output, "<span></span>");

# named tag
$input = "span#test";
$output = $t->process( $input );
is( $$output, "<span id='test' ></span>");

# with properties
$input .= " data-value='test'";
$output = $t->process( $input );
is( $$output, "<span id='test' data-value='test'></span>");

# named tag
$input = "span.test";
$output = $t->process( $input );
is( $$output, "<span class='test'></span>");

#implicit div
$input = "#test";
$output = $t->process( $input );
is( $$output, "<div id='test'></div>");

#implicit div
$input = ".test";
$output = $t->process( $input );
is( $$output, "<div class='test'></div>");

