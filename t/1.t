use Test::More tests => 4;
use File::Slurp;
BEGIN { unlink("t/test.db"); }
use Email::Store "dbi:SQLite:dbname=t/test.db";
Email::Store->setup;
ok(1, "Set up");

my $i;
use Email::Folder;
{ no warnings;
*Email::Folder::bless_message = sub { $_[1] }; # Raw mails
}
$| =1;
print "# Threading 10 mails\n";
print "# ";
for (Email::Folder->new("t/maypole-200406")->messages) {
    print ".";
    Email::Store::Mail->store($_);
}
print "\n";

my $parent = Email::Store::Mail->retrieve('20040601115553.759d77ec@bugs');
my $child = $parent->container->child->message;
is ($child->container->message, $child, "Roundtripable");
is ($child->message_id, '20040601091735.GA10279@mag-sol.com', "First child");
is ($child->container->child->child->message->message_id,
    '40BCAA44.3030100@thefeed.no', "Grandchild");
