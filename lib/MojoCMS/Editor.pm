package MojoCMS::Editor;
use Mojo::Base 'Mojolicious::Controller';

use Mojo::JSON;
my $json = Mojo::JSON->new;

sub ws_update {
  my $self = shift;
  Mojo::IOLoop->stream($self->tx->connection)->timeout(300);
  $self->on(message => sub {
    my ($self, $message) = @_;
    my $data = $json->decode($message);

    my $schema = $self->schema;
    my $store = delete $data->{store};

    if ($store eq 'pages') {
      unless($data->{title}) {
        $self->send('Not saved! A title is required!');
        return;
      }
      my $author = $schema->resultset('User')->single({name=>$self->session->{username}});
      $data->{author_id} = $author->id;
      $schema->resultset('Page')->update_or_create(
        $data, {key => 'pages_name'},
      );
      $self->store_menu();
    } elsif ($store eq 'main_menu') {
      $self->store_menu($data->{list});
    }
    $self->send('Changes saved');
  });
}

sub edit_page {
  my $self = shift;
  my $name = $self->param('name');
  $self->title( "Editing Page: $name" );
  $self->content_for( banner => "Editing Page: $name" );

  my $schema = $self->schema;

  my $page = $schema->resultset('Page')->single({name => $name});
  if ($page) {
    my $title = $page->title;
    $self->stash( title_value => $title );
    $self->stash( input => $page->md );
  } else {
    $self->stash( title_value => '' );
    $self->stash( input => "Hello World" );
  }

  $self->render( 'edit' );
}

sub edit_menu {
  my $self = shift;
  my $name = 'main';
  my $schema = $self->schema;

  my %active = 
    map { $_ => 1 } 
    @{ $json->decode(
      $schema->resultset('Menu')->single({name => $name})->list
    )};
  
  my ($active, $inactive);
  my @pages = $schema->resultset('Page')->all;
  for my $page ( @pages ) {
    next unless $page;
    my $name = $page->name;
    my $id   = $page->id;
    next if $name eq 'home';
    exists $active{$id} ? $active : $inactive 
      .= sprintf qq{<li id="pages-%s">%s</li>\n}, $id, $page->title;
  }

  $self->title( 'Setup Main Navigation Menu' );
  $self->content_for( banner => 'Setup Main Navigation Menu' );
  $self->render( menu => 
    active   => Mojo::ByteStream->new( $active   ), 
    inactive => Mojo::ByteStream->new( $inactive ),
  );
}

sub store_menu {
  my $self = shift;
  my $schema = $self->schema;

  my $name = (@_ == 0 or ref $_[0]) ? 'main' : shift();
  my $list = @_ ? shift() : $json->decode($schema->resultset('Menu')->single({name => $name})->list);
  
  my @pages = 
    map { my $page = $_; $page =~ s/^pages-//; $page}
    grep { ! /^header-/ }
    @$list;
  
  my $rs = $schema->resultset('Page');
  my $html;
  for my $id (@pages) {
    my $page = $rs->single({id => $id});
    $html .= sprintf '<li><a href="/pages/%s">%s</a></li>', $page->name, $page->title;
  }

  $schema->resultset('Menu')->update(
    {
      html => $html || '',
      list => $json->encode(\@pages),
    },
    { key => $name }
  );
}

1;
