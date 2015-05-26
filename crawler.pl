use strict;
use warnings;
use LWP::Simple;
use LWP::UserAgent;
use Data::Dumper;
use utf8;
binmode(STDOUT, ":utf8");
$| = 1;

my $DIR = "http://dir.yahoo.co.jp";
my $japan_html = get($DIR . "/Regional/Japanese_Regions/");

my @pref_list = ();
push @pref_list, { "url" => "/Regional/Japanese_Regions/Hokkaido/", "name"=>"北海道" };
while($japan_html =~ m|<a href="(/Regional/Japanese_Regions/.+/.+/?/)\?.+>(.+)</a>|g) {
    push @pref_list, { "url" => $1, "name" => $2 };
}
push @pref_list, { "url" => "/Regional/Japanese_Regions/Okinawa/", "name"=>"沖縄" };

foreach my $pref (@pref_list) {

    my $pref_baseurl = $pref->{url};
    my $pref_name = $pref->{name};

    my $citylist_html = get($DIR . $pref_baseurl . "Cities/");
    while($citylist_html =~ m|(${pref_baseurl}Cities/.+?/)\?.+>(.+)</a>.+<span class="kana">(.+)</span>|g) {
        my $i = {};

        my $city_baseurl = $1;
        my $city_name = $2;
        my $city_kana = $3;

        $i->{pref_name} = $pref_name;
        $i->{city_name} = $city_name;
        $i->{city_kana} = $city_kana;
        $i->{city_path} = lc($city_baseurl);
        $i->{city_path} =~ s|/regional/japanese_regions||;

        my $city_html = get($DIR . $city_baseurl);
        my @nearby = ();
        if ($city_html =~ m|<div class="near_list" id="neighbor">(.+?)</div>|s) {
            my $nearby = $1;
            while($nearby =~ m|<a href="http://dir.yahoo.co.jp/regional/japanese_regions(.+?/)\?|g) {
                push @nearby,  $1;
            }
        }

        $i->{city_nearby} = \@nearby;

        my ($gov_hp, $gov_hp_title, $gov_tw);
        my $gov_html = get($DIR . $city_baseurl . "Government/Office/");
        if($gov_html =~ m|<div class="site_list" id="ofclsite">.+?<th>.+?</th>.+?<td>.+?<a.+?href="(.+?)".+?>(.+?)</a>|s) {
            $gov_hp = $1;
            $gov_hp_title = $2;
        }
        if($gov_html =~ m|href="http://twitter.com/(.+?)"|) {
            $gov_tw = $1;
        }

        $i->{gov_hp} = $gov_hp;
        $i->{gov_hp_title} = $gov_hp_title;
        $i->{gov_tw} = $gov_tw || "";

        my ($jiscode, $lat, $lon);
        if ($city_html =~ m|(http://weather.yahoo.co.jp/weather/jp/.+/.+/.+?\.html)|) {
            my $weather_url = $1;
            $jiscode = ($weather_url =~ m|/(\d+)\.html|)[0];
            if (length($jiscode) == 4) {
                $jiscode = "0" . $jiscode;
            }

            my $user_agent = 'Mozilla/5.0 (iPhone; CPU iPhone OS 8_2 like Mac OS X) AppleWebKit/600.1.4 (KHTML, like Gecko) Version/8.0 Mobile/12D508 Safari/600.1.4';
            my $ua = LWP::UserAgent->new;
            $ua->agent($user_agent);
            my $response = $ua->get($weather_url);
            if ($response->is_success) {
                my $sp_weatherhtml = $response->content;
                if ($sp_weatherhtml =~ m|<div class="zoomr_btn">.+?<a href="(http.+?)"|s) {
                    my $zm = get($1);
                    if ($zm =~ m|<meta property="og:url" content="http://weather.yahoo.co.jp/weather/zoomradar/\?lat=(.+)&lon=(.+)&z=|s) {
                        $lat = $1;
                        $lon = $2;
                    }
                }
            }
        }

        $i->{jiscode} = $jiscode;
        $i->{lat} = $lat;
        $i->{lon} = $lon;

        print_line($i);
    }
}


sub print_line {
    my $i = shift;

    print join "\t", (
        $i->{jiscode},
        $i->{pref_name},
        $i->{city_name},
        $i->{city_kana},
        $i->{city_path},
        $i->{lat},
        $i->{lon},
        $i->{gov_hp},
        $i->{gov_hp_title},
        $i->{gov_tw},
        join(",", @{$i->{city_nearby}})
        );
    print "\n";
#    sleep 1;
}
