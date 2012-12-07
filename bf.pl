#!/usr/bin/perl

#Use
use strict;
use warnings; 
use Switch;
use Getopt::Long;
use Pod::Usage;

#Parse command line options
my ($file, $log, $wrap, $help, $man, $size);
my $commands = '+-<>[].,';

GetOptions(
    'file=s'      => \$file,
    'logfile=s'   => \$log,
    'wrap!'       => \$wrap,
    'commands=s'  => \$commands,
    'help'        => \$help,
    'man'         => \$man,
    'size=i'      => \$size,
    );

if($log) {
    open LOG, ">", $log or die "Can't open logfile $log: $!\n";
}

#Read program
my $prog;

{
    local $/ = undef;
    open( FH, $file ) or die "Can't open bf file $file: $!\n";
    $prog = <FH>;
    close FH;
}

$prog =~ s/[^\Q$commands\E]//g;
my @prog = split(//, $prog);
print LOG "program is @prog\n" if($log);

my $pc = 0;
my $ptr = 0;
my @arr;
my @loop;

#Execute
while ($pc < @prog) { 
    my $cmd = $prog[$pc];
    if($log){ 
        print LOG "command $pc = $cmd\nptr is at $ptr\n"if($log);
    }
    if(!defined($arr[$ptr])) {
        $arr[$ptr] = 0;
    }
    switch($cmd) {
        case '+' {
            if(++$arr[$ptr] > 255) {
                if($wrap) {
                    $arr[$ptr] = 0 ;
                } else {
                    die "Cannot increment value past 255\nTry running again with -wrap\n";
                }
            }
            $pc++;
        }
        case '-' {
            if(--$arr[$ptr] < 0) {
                if($wrap) {
                    $arr[$ptr] = 255 
                } else {
                    die "Cannot decrement value past 0\nTry running again with -wrap\n";
            }
            }
            $pc++;
        }
        case '<' {
            $ptr--;
            if($ptr < 0) {
                if(!$size) {
                    die "Pointer cannot go below 0\n";
                } else {
                    $ptr = $size - 1;
                }
            }
            $pc++;
        }
        case '>' {
            $ptr++;
            if($size && ($ptr >= $size)) {
                $ptr = 0;
            }
            $pc++;
        }
        case '[' {
            if($arr[$ptr] != 0) {
                push @loop, $pc;
            } else {
                my $count = 1;
                while($count) {
                    $pc++;
                    if($prog[$pc] eq '[') {
                        $count++;
                    } elsif ($prog[$pc] eq ']') {
                        $count--;
                    }
                }
                print LOG "loop @loop\n" if($log);
            }
            $pc++;
        }
        case ']' {
            print LOG "setting pc to $loop[$#loop]\n"if($log);
            $pc = $loop[$#loop];
            pop @loop;
            print LOG "loop @loop\n" if($log);
        }
        case '.' {
            print chr($arr[$ptr]);
            $pc++;
        }
        case ',' {
            my $ip = <STDIN>;
            my @iped = split(//, $ip, 1);
            $arr[$ptr] = ord($iped[0]);
            $pc++;
        }
    }
    if($log){ 
        print LOG "arr is @arr\n arrsize is $#arr + 1\n";
        for (my $i = 0; $i < @arr || 
             $i < $ptr + 1; ++$i) {
            my $tmpV;
            if(defined ($arr[$i])) {
                $tmpV = $arr[$i];
            } else {
                $tmpV = ' ';
            }
            if($i == $ptr) {
                print LOG  "\<$tmpV\>";
            }else {
                print LOG  "\[$tmpV\]";
            }
        }
        print LOG  "\n";
        for (my $i = 0; $i < @arr || $i < $ptr + 1; ++$i) {
            my $tmpV = $arr[$i];
            my $tmpC;
            if(defined($arr[$i]) && $tmpV>= 32 && $tmpV<= 126) {
                $tmpC = chr($arr[$i]);
            } else {
                $tmpC = ' ';
            }                
            if($i == $ptr) {
                print LOG  "\<$tmpC\>";
            }else {
                print LOG  "\[$tmpC\]";
            }
        }
        print LOG  "\n\n";
    }
}

print LOG "<END>\n" if($log);
