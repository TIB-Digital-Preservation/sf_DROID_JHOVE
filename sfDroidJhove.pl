#sfDroidJhove Version 1.1
use strict;
use warnings;
use Text::CSV;
use XML::LibXML;
use File::Copy;
use File::Basename;
#set DROID and sf in environment variables
#Droid umstellen auf MaxByteScan -1 und Archivordner sollen NICHT ausgepackt werden.

#search for signature updates for sf and DROID
qx(droid.bat -d);
qx(sf -update);

my $dir = "/path/to/dir";
my $output = "/path/to/output/dir";
#sollen Dateien, die untersucht werden müssen (nicht wohlgeformt, nicht valide, mehrere PUIDs), in entsprechende Ordner kopiert werden?
#Optionen: "yes" oder "no"
my $copyFiles = "yes";

#make hash of all puids and respective jhove modules
my %jhoveModules = ("fmt/17"=>"PDF-hul", "fmt/18"=>"PDF-hul", "fmt/19"=>"PDF-hul", "fmt/20"=>"PDF-hul", "fmt/14"=>"PDF-hul", "fmt/15"=>"PDF-hul", "fmt/16"=>"PDF-hul", "fmt/95"=>"PDF-hul", "fmt/144"=>"PDF-hul", "fmt/145"=>"PDF-hul", "fmt/146"=>"PDF-hul", "fmt/147"=>"PDF-hul", "fmt/148"=>"PDF-hul", "fmt/157"=>"PDF-hul", "fmt/158"=>"PDF-hul", "fmt/276"=>"PDF-hul", "fmt/354"=>"PDF-hul", "fmt/476"=>"PDF-hul", "fmt/477"=>"PDF-hul", "fmt/478"=>"PDF-hul", "fmt/479"=>"PDF-hul", "fmt/480"=>"PDF-hul", "fmt/481"=>"PDF-hul", "fmt/488"=>"PDF-hul", "fmt/489"=>"PDF-hul", "fmt/490"=>"PDF-hul", "fmt/491"=>"PDF-hul", "fmt/492"=>"PDF-hul", "fmt/493"=>"PDF-hul", "fmt/152"=>"TIFF-hul", "fmt/7"=>"TIFF-hul", "fmt/8"=>"TIFF-hul", "fmt/9"=>"TIFF-hul", "fmt/10"=>"TIFF-hul", "x-fmt/399"=>"TIFF-hul", "x-fmt/388"=>"TIFF-hul", "x-fmt/387"=>"TIFF-hul", "fmt/155"=>"TIFF-hul", "fmt/353"=>"TIFF-hul", "fmt/154"=>"TIFF-hul", "fmt/153"=>"TIFF-hul", "fmt/156"=>"TIFF-hul", "fmt/436"=>"TIFF-hul", "fmt/437"=>"TIFF-hul", "fmt/730"=>"TIFF-hul", "fmt/41"=>"JPEG-hul", "fmt/42"=>"JPEG-hul", "fmt/43"=>"JPEG-hul", "x-fmt/44"=>"JPEG-hul", "fmt/112"=>"JPEG-hul", "fmt/113"=>"JPEG-hul", "fmt/149"=>"JPEG-hul", "fmt/151"=>"JPEG-hul", "x-fmt/390"=>"JPEG-hul", "x-fmt/391"=>"JPEG-hul", "x-fmt/398"=>"JPEG-hul", "fmt/150"=>"JPEG-hul", "x-fmt/392"=>"JPEG2000-hul","fmt/1"=>"WAVE-hul", "fmt/2"=>"WAVE-hul", "fmt/6"=>"WAVE-hul", "fmt/141"=>"WAVE-hul", "fmt/142"=>"WAVE-hul", "fmt/143"=>"WAVE-hul", "fmt/527"=>"WAVE-hul", "fmt/703"=>"WAVE-hul", "fmt/704"=>"WAVE-hul", "fmt/705"=>"WAVE-hul", "fmt/706"=>"WAVE-hul", "fmt/707"=>"WAVE-hul", "fmt/708"=>"WAVE-hul", "fmt/709"=>"WAVE-hul", "fmt/710"=>"WAVE-hul", "fmt/711"=>"WAVE-hul", "x-fmt/389"=>"WAVE-hul", "x-fmt/396"=>"WAVE-hul", "x-fmt/397"=>"WAVE-hul", "fmt/414"=>"AIFF-hul", "fmt/2"=>"AIFF-hul", "fmt/6"=>"AIFF-hul", "fmt/141"=>"AIFF-hul", "fmt/142"=>"AIFF-hul", "fmt/143"=>"AIFF-hul", "fmt/135"=>"AIFF-hul", "fmt/136"=>"AIFF-hul", "fmt/3"=>"GIF-hul", "fmt/4"=>"GIF-hul", "x-fmt/227"=>"XML-hul", "fmt/121"=>"XML-hul", "fmt/120"=>"XML-hul", "fmt/103"=>"XML-hul", "fmt/102"=>"XML-hul", "fmt/101"=>"XML-hul", "x-fmt/16"=>"UTF8-hul");

##create and open reports
open (OUT_MATCH,">:encoding(UTF-8)","$output/FilesMatch.csv");
print OUT_MATCH "DROID-ID,Pfad,DROID Format Anzahl,DROID Format,sf Format,Jhove\n";

open (OUT_NOMATCH,">:encoding(UTF-8)","$output/FilesUncertain.csv");
print OUT_NOMATCH "DROID-ID,Pfad,DROID Format Anzahl,DROID Format,sf Format,Jhove\n";

#create outputfolder for jhove
unless (-d "$output/jhove"){
  mkdir "$output/jhove";
}

if ($copyFiles eq "yes"){
	#create outputfolder for not valid files for further analysis
	unless (-d "$output/not_valid"){
	  mkdir "$output/not_valid";
	}

	#create outputfolder for not well-formed files for further analysis
	unless (-d "$output/not_wellformed"){
	  mkdir "$output/not_wellformed";
	}

	#create outputfolder for files with multiple format hits for further analysis
	unless (-d "$output/multiple_format"){
	  mkdir "$output/multiple_format";
	}
}

print "DROID-Analyse\n";
qx(droid.bat -R -a $dir -p "$output/results_droid.droid");
qx(droid.bat -p "$output/results_droid.droid" -E "$output/results_droid.csv");

print "sf analysis\n";
my $previousRowID = "-1";
my $previousRowFmt = "-1";
my $countPUIDs = 1;
#csv einlesen, objekte erzeugen und jedem objekt sein droid-ergebnis zuweisen hierbei multiple format hits beachten
my $csv = Text::CSV->new();
open (my $fh, "<:encoding(utf8)" ,"$output/results_droid.csv") or die "Couldn't open file: $!";
while (my $row = $csv->getline ($fh)) {
      if ($row->[8] =~ m/File|Container/){
        my $path = $row->[3];
        my $droid_fmt = $row->[14];
        my $droid_fmtcount = $row->[13];

        #start of sf analysis
        print ".";
        my $escPath = $path;
        $escPath =~ s/\\\$/\\\\\$/;
        $escPath =~ s/\$/\\\$/;
        #print "escaped path: ".$escPath."\n";
        #Add path to sf.exe
        my $resSf = qx(sf -csv "$escPath");
        chomp($resSf);
        $resSf =~ m/([x-]*fmt\/\d*)/g;
        $resSf = $1;
        #print "\n-----".$resSf."-----\n";

        #comparison of results of sf and droid, split into different outputfiles
        if ($droid_fmtcount == 1 && $resSf eq $droid_fmt){
          #jhove analysis for files which match
          my $jhove = jhoveAnalysis($row->[0],$resSf,$path);
          #write reports for matching
          print OUT_MATCH "\"".$row->[0]."\",\"".$path."\",\"".$droid_fmtcount."\",\"".$droid_fmt."\",\"".$resSf."\",\"".$jhove."\",\n";
          if ($jhove =~ m/Not well-formed/){
            copyFurtherAnalysis($path,$output."/not_wellformed",$row->[0]);
          } elsif ($jhove =~ m/Well-Formed, but not valid/){
            copyFurtherAnalysis($path,$output."/not_valid",$row->[0]);
          }
        } else {
          #files which don't match or have more than one puid
          if ($droid_fmtcount <= 1) { #mit 0 DROID Treffern oder wenn 1 DROID Treffer, aber sf und DROID nicht zum gleichen Ergebnis kommen
            print OUT_NOMATCH "\"".$row->[0]."\",\"".$path."\",\"".$droid_fmtcount."\",\"".$droid_fmt."\",\"".$resSf."\",\"no definite result by sf and droid, therefore not processed by JHOVE\"\n";
            copyFurtherAnalysis($path,$output."/multiple_format",$row->[0]);
          } elsif ($droid_fmtcount > 1 && $row->[0] == $previousRowID) {
            $droid_fmt = $droid_fmt." , ".$previousRowFmt;
            $countPUIDs++;
            if ($countPUIDs == $droid_fmtcount) {#erst wenn die Anzahl der PUIDs in $doird_fmt übereinstimmt mit der Anzahl laut $droid_fmtcount in den report
              print OUT_NOMATCH "\"".$row->[0]."\",\"".$path."\",\"".$droid_fmtcount."\",\"".$droid_fmt."\",\"".$resSf."\",\"no definite result by sf and droid, therefore not processed by JHOVE\"\n";
              copyFurtherAnalysis($path,$output."/multiple_format",$row->[0]);
              $countPUIDs = 1; #counter zurücksetzen
            }
          } #wenn in Zeile mehrere DROID-Treffer genannt sind, aber die vorherige ID nicht übereinstimmt,
            #dann wird nur der DROID-Wert in der $previousRowFmt gespeichert, und bei dem nächsten Durchlauf genutzt
        }
        $previousRowID = $row->[0];
        $previousRowFmt = $droid_fmt;
      }
}
close OUT_MATCH;
close OUT_NOMATCH;
close $fh;


#erstellung aller reports
#asuwertung  @fmt_unknown
print "\nwrite reports\n";
my %overviewPUIDs;
my %overviewUncertain;
my %overviewJhove;
open (my $fhMatch, "<:encoding(utf8)" ,"$output/FilesMatch.csv") or die "Couldn't open file: $!";
while (my $row = $csv->getline ($fhMatch)) {
  next if $. == 1; #skip first line
  my $puid = $row->[3];
  #print "puid ->".$puid."\n";
  #Auswertung der PUIDs
  if (exists $overviewPUIDs{$puid}){
    my $count = $overviewPUIDs{$puid};
    $count++;
    $overviewPUIDs{$puid} = $count;
  } else {
    $overviewPUIDs{$puid} = 1;
  }
  #Auswertung der Jhove Ergebnisse
  my $jhove = $row->[5];
  if (exists $overviewJhove{$jhove}){
    my $count = $overviewJhove{$jhove};
    $count++;
    $overviewJhove{$jhove} = $count;
  } else {
    $overviewJhove{$jhove} = 1;
  }
}
close $fhMatch;
open (my $fhUncer, "<:encoding(utf8)" ,"$output/FilesUncertain.csv") or die "Couldn't open file: $!";
while (my $row = $csv->getline ($fhUncer)) {
  next if $. == 1; #skip first line
  my $droid = $row->[3];
  my $sf = $row->[4];
  my $droid_count = $row->[2];
  #-multiple puids
  if ($droid_count>1){
    addToHash("multiple PUIDs");
  #-both unknown
  } elsif (($sf eq "unknown") && ($droid eq "unkown")){
      addToHash("both unknown");
  #-sf unknown
  } elsif ($sf eq "unknown"){
      addToHash("sf unknown");
  #droid unknown
  } elsif ($droid eq "unknown"){
      addToHash("droid unknown");
  #-no match
  } else {
      addToHash("no match");
  }
}
close $fhUncer;

open (REPORT,">:encoding(UTF-8)","$output/report.csv");
print REPORT '"PUID";"Anzahl"'."\n";
while ((my $k,my $v)=each %overviewPUIDs){
  print REPORT '"'.$k.'";"'.$v.'"'."\n";
}
print REPORT "\n".'"Nicht eindeutige Ergebnisse";"Anzahl"'."\n";
while ((my $k,my $v)=each %overviewUncertain){
  print REPORT '"'.$k.'";"'.$v.'"'."\n";
}
print REPORT "\n".'"Jhove-Status";"Anzahl"'."\n";
while ((my $k,my $v)=each %overviewJhove){
  print REPORT '"'.$k.'";"'.$v.'"'."\n";
}
close REPORT;

###############subroutine start jhove analysis
sub jhoveAnalysis{
  my $id = $_[0];
  my $puid = $_[1];
  my $path = $_[2];
  my $status;
  if ($path =~ m/.*\&.*/){
    print $path." hat & im Dateiname, bitte extra analysieren\n";
    $status = "jhove could not analyse due to filename";
  } else {
    my $escPath = $path;
    $escPath =~ s/\\\$/\\\\\$/;
    $escPath =~ s/\$/\\\$/;
    #$escPath =~ s/\&/\\\&/;
    my $outputFile = "$output/jhove/$id.xml";
    $status = getJhoveStatus($puid,$escPath,$outputFile);
  }
  return $status;
}

###############subroutine call getJhove
sub getJhoveStatus{
  my ($puid,$path,$outputFile) = ($_[0],$_[1],$_[2]);
  my $module;
  my $status;
  if (exists $jhoveModules{$puid}){
    $module = $jhoveModules{$puid};
    qx(timeout 600.0s jhove.bat -m $module -h xml -o "$outputFile" "$path");
    if   ($? == -1  ){
      print "failed to execute: $!" ;
    } elsif ($?&127) {
      print "died, signal %d, %scoredump", $?&127, $?&128?'':'no ';
    } elsif ($?>>8==124) {
      $status = "Jhove took more than 10 Minutes";
    } else {
      if (-s $outputFile == 0) {
        $status = "Jhove report is empty";
      } else {
        open(JHOVEFILE,$outputFile) or die;
    		my $line = <JHOVEFILE>;
    		until ($line =~ m/.*status.*/){
    			$line = <JHOVEFILE>;
    			$status = $line;
    		}
    		close(JHOVEFILE);
    		$status =~ s/.*<status>(.*)\<\/status>.*/$1/;
    		$status =~ s/\n//;
    		#print $status;
      }
    }
  } else {
    $status =$puid." not in Hash of jhoveModules, therefore not processed by JHOVE";
  }
  return $status;
}

########################subroutine
sub addToHash{
  my $case = $_[0];
  if (exists $overviewUncertain{$case}){
    my $count = $overviewUncertain{$case};
    $count++;
    $overviewUncertain{$case} = $count;
  } else {
    $overviewUncertain{$case} = 1;
  }
}

###############subroutine copies file to folder for further analysis
sub copyFurtherAnalysis{
	my $filePath = $_[0];
	my $folderPath = $_[1];
	my $droid_id =  $_[2];
	#print "kopiert ".$filePath;
	#print " nach ".$folderPath."\n";
  $filePath =~ s/\\/\//g;
  my $filename = basename($filePath);
  print $filename."\n";
	my $newFileName = $folderPath."/".$droid_id."_".$filename;
  print "alt: ".$filePath."\nneu: ".$newFileName."\n";
	if ($copyFiles eq "yes") {
		my $success = copy ($filePath, $newFileName);
			if ($success!=1){
			print "Fehler beim kopieren von ".$filePath."\n";
		}
	}
}
