# Usage: mutator.pl FILE
use File::Copy qw/mv cp/;

($f) = @ARGV;

%m = (
	0 => 'OK',
	256 => 'FAIL',
);


open(my $FH, $f) or die();

my @all;

# slurp
while(<$FH>)
{
	push @all, $_;
}

close($FH);
               
$mutator = "==";
$replacement = "!=";

# first pass. Count the number of mutators.
foreach my $line (@all)
{
	if ($line =~ m/$mutator/)
	{
		$count++;
	}
}
print "You have $count occurences of $mutator\n";

# second pass. Create mutants.
foreach my $n (1 .. $count)
{
	@copy = @all;
	$i = 0;

	open(my $OH, '>', $f . "." . $n) or next;
	foreach my $line (@copy)
	{
		if ($line =~ m/$mutator/)
		{
			$i++;
			if ($n eq $i)
			{
				$line =~ s/$mutator/$replacement/;
			}
		}
		print $OH $line;
	}
	close($OH);
}

# store away original.
mv($f, $f . ".orig");

# move each mutant to original
foreach my $n (1 .. $count)
{
	mv($f . "." . $n, $f) or die "$!";
	$res = system("go test");
	warn "Result for $n = $res";
	mv($f, $f . ".$n." . $m{$res});
}

unlink($f);
cp($f . ".orig", $f);

