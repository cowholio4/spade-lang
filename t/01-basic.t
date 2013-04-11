#!/usr/bin/perl
use Test::More tests => 10;

use Data::Dumper::Simple;
use Spade::Template;

my $t = Spade::Template->new();
isa_ok( $t, 'Spade::Template' );
my ( $input, $output );

# with properties
$input = "span#test data-value='test'";
$output = $t->process( $input );
is( $$output, "<span id='test' data-value='test'></span>");

$input = "";
$output = $t->process( $input );
is( $$output, undef, $input);

$input = "div";
$output = $t->process( $input );
is( $$output, "<div></div>",$input);


$input = "span";
$output = $t->process( $input );
is( $$output, "<span></span>",$input);

# named tag
$input = "span#test";
$output = $t->process( $input );
is( $$output, "<span id='test'></span>",$input);

# with properties
$input = "span#test data-value='test'";
$output = $t->process( $input );
is( $$output, "<span id='test' data-value='test'></span>", $input);

# named tag
$input = "span.test";
$output = $t->process( $input );
is( $$output, "<span class='test'></span>", $input);

#implicit div
$input = "#test";
$output = $t->process( $input );
is( $$output, "<div id='test'></div>", $input);

#implicit div
$input = ".test";
$output = $t->process( $input );
is( $$output, "<div class='test'></div>", $input);

