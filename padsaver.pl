#!/usr/bin/perl -s
#
## Etherpad-Lite Textsaver via api

use strict;
use warnings;
use utf8;

use Config::Simple;
use File::Basename;

use LWP::Simple;
use LWP::UserAgent;
use JSON;

# make a new config reader object
my $currentpath  = dirname(__FILE__);
my $cfg          = new Config::Simple("$currentpath/padsaver.config");
my $apiurl = $cfg->param('apiurl');
my $apikey = $cfg->param('apikey');

my $ua = LWP::UserAgent->new(ssl_opts => { verify_hostname => 0 });
my $query=$apiurl."/api/1.2.7/listAllPads?apikey=".$apikey;

# indicates server ssl support
my $secure;
if ($apiurl =~ /^.*https:/) {
  $secure = 1;
}
elsif ($apiurl =~ /^.*http:/) {
  $secure = 0;  
}
else {
  $secure = -1;
  die "Protocol is not valid\n";
}


# query result
my $res;
my $padlist_data;
my $padtext_data;

# make a JSON parser object
my $json = JSON->new->allow_nonref;

# get JSON via LWP and decode it to hash
if ($secure) {
  $res      = $ua->get("$query");
  die "Couldn't get it!" unless defined $res->content;
  $padlist_data = $json->decode($res->content);
}
else {
  $res      = get("$query");
  die "Couldn't get it!" unless defined $res;
  $padlist_data = $json->decode($res);
}


  
if ($padlist_data->{"message"} eq "ok"){
    
  my $padlist = $padlist_data->{"data"}->{"padIDs"};

  mkdir("$apikey",0777);
    
  # insert Podcasts in DB
  foreach my $pad (@$padlist) {
  
    # build new query
    $query=$apiurl."/api/1.2.7/getText?padID=".$pad."&apikey=".$apikey;
  
    # get it
    if ($secure) {
      $res      = $ua->get("$query");
      die "Couldn't get it!" unless defined $res->content;
      $padtext_data = $json->decode($res->content);
    }
    else {
      $res      = get("$query");
      die "Couldn't get it!" unless defined $res;
      $padtext_data = $json->decode($res);
    }
 
    #if res is valid 
    if ($padtext_data->{"message"} eq "ok"){
      my $padtext = $padtext_data->{"data"}->{"text"};

      # save it
      open(my $fh, '>', $apikey."/".$pad.".txt") or die "Could not open file '$pad.txt' $!";
      print $fh $padtext;
      close $fh;
    }
    else { # could't get text
      print "Error on: $pad -- Not ok\n";
    }
  }
}
else{ #something goes badly wrong here....
  print "Error on retrieving padlist\n";
}
