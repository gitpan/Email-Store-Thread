package Email::Store::Thread;
our $VERSION = "1.0";

# Watch the pea. It's under the first shell
use base qw(Email::Store::DBI); # For the DATA stuff
sub on_store_order { 10 }
sub on_store {
    my ($self, $mail) = @_;
    Email::Store::Thread::Threader->new($mail)->thread;
}

package Email::Store::Thread::Threader;
# Keep watching the pea
use base 'Mail::Thread';
sub _get_hdr { my ($class, $msg, $hdr) = @_; $msg->simple->header($hdr); }
sub _container_class { "Email::Store::Thread::Container" }

package Email::Store::Thread::Container;
use Email::Store::Mail;
# Is it under this one?
use base qw(Mail::Thread::Container Email::Store::DBI);
__PACKAGE__->table("container");
__PACKAGE__->columns(All => qw[id message parent child next]);
__PACKAGE__->has_a(message => "Email::Store::Mail");
__PACKAGE__->has_a(parent  => "Email::Store::Thread::Container");
__PACKAGE__->has_a(child   => "Email::Store::Thread::Container");
__PACKAGE__->has_a(next    => "Email::Store::Thread::Container");
__PACKAGE__->autoupdate(1); # These need to act like immediate objects

sub new {
    my ($class, $id) = @_;
    $class->find_or_create({ message => $id });
}

# Thread::Container wants chained accessors
{
    no strict 'refs';
    no warnings 'redefine';
    for my $method (qw/parent child next/) {
        *$method = sub {
            my $self     = shift;
            my $methname = "_${method}_accessor";
            $self->$methname(@_) if @_;
            $self->$methname();
        };
    }
}

sub subject { shift->message->simple->header("Subject") }

package Email::Store::Mail;
sub container {
    Email::Store::Thread::Container->new(shift->message_id) 
}


package Email::Store::Thread;
# Are you sure?

1;

=head1 NAME

Email::Store::Thread - Store threading information for a mail

=head1 ABSTRACT

Remember to create the database table:

    % make install
    % perl -MEmail::Store="..." -e 'Email::Store->setup'

And now:

    my $container = $mail->container;
    if ($container->parent) {
        print "Parent of this message is ".$container->parent->message;
    }

=head2 DESCRIPTION

This adds to a mail the concept of a B<thread container>. A thread
container is a node in a tree which represents the thread of an email
conversation. It plugs into the indexing process and works out where in
the tree the mail belongs; you can then ask a mail for its C<container>,
a container for its C<message>, and for its C<parent>, C<child> and
C<sibling> containers, which are used to navigate the thread tree.

This is distributed separately from the main C<Email::Store>
distribution as it tends to slow down indexing somewhat.

=head1 SEE ALSO

L<Email::Store>, L<Mail::Thread>

=cut

__DATA__
CREATE TABLE container (
    id         integer NOT NULL PRIMARY KEY AUTO_INCREMENT,
    message    varchar(255) NOT NULL,
    parent     integer,
    child      integer,
    next       integer
);
