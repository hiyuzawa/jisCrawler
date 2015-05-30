use strict;
use warnings;
use JSON;
use Data::Dumper;

my $jis_path = {};

open(IN, "jis_data.tsv");
while(<IN>) {
    chomp;
    my @item = split "\t";
    $jis_path->{$item[4]} = $item[0];
}
close(IN);

my $data_hash = {};

open(IN, "jis_data.tsv");
while(<IN>) {
    my $i;
    chomp;
    my @item = split "\t";

    $i->{jis} = $item[0];
    $i->{pref} = $item[1];
    $i->{name} = $item[2];
    $i->{read} = $item[3];
    $i->{path} = $item[4];
    $i->{lat} = $item[5];
    $i->{lon} = $item[6];
    $i->{hp} = $item[7];
    $i->{hp_name} = $item[8];
    $i->{tw} = $item[9];

    my @nearby_path_array = split ",", $item[10];
    my @nearby_jis_array = map {$jis_path->{$_}} @nearby_path_array;
    $i->{nearby} = \@nearby_jis_array;

    $data_hash->{$i->{jis}} =  $i;
}
close(IN);

my $json = JSON->new();

print $json->encode($data_hash);
