#
# (c) Jan Gehring <jan.gehring@gmail.com>
#
# vim: set ts=2 sw=2 tw=0:
# vim: set expandtab:

package Rex::CLI::Cmd::overlord;

use Moo;
use MooX::Cmd;
use MooX::Options;

use Data::Dumper;
use LWP::UserAgent;

use File::Spec;
use YAML;

use HTTP::Request;
use HTTP::Request::Common;

with "Rex::CLI::Command";

option push => (
  is    => 'ro',
  doc   => 'Upload Rexfile and contents to your Overlord server',
  short => 'p',
);

option overlord => (
  is       => 'ro',
  doc      => 'The URL to your Overlord server.',
  short    => 'o',
  required => 1,
  format   => 's',
);

sub execute {
  my ( $self, $args, $chain ) = @_;

  if ( $self->push ) {
    $self->upload();
  }
}

sub upload {
  my ($self) = @_;

  if ( !-f "meta.yml" ) {
    Rex::Logger::info(
      "No meta.yml file found. You need a meta.yml file to upload this project to your Overlord server.",
      "error"
    );
    CORE::exit(1);
  }

  my $ref = YAML::LoadFile("meta.yml");

  if ( !exists $ref->{Name} ) {
    Rex::Logger::info(
      "No name given in meta.yml. Please add the name. (Ex.: Name: MyShinyRexfile)",
      "error"
    );
    CORE::exit(1);
  }

  if ( $ref->{Name} !~ m/^[A-Za-z_0-9]+$/ ) {
    Rex::Logger::info(
      "The name must only contain these letters: a-z, 0-9, A-Z, _", "error" );
    CORE::exit(1);
  }

  if ( !exists $ref->{Version} ) {
    Rex::Logger::info(
      "No version given in meta.yml. Please add the version. (Ex.: Version: 1.0)",
      "error"
    );
    CORE::exit(1);
  }

  if ( $ref->{Version} !~ m/^\d+\.\d+$/ ) {
    Rex::Logger::info(
      "Version syntax wrong. The version must follow the syntax: \\d+\\.\\d+. (Ex.: 1.41)",
      "error"
    );
    CORE::exit(1);
  }

  my $time = time;
  my $tmp_file =
    File::Spec->catfile( File::Spec->tmpdir(), "upload_$time.tar.gz" );
  my $cmd = "tar czf $tmp_file . >/dev/null 2>&1";
  Rex::Logger::debug("Creating temporary upload file: $tmp_file.");

  CORE::system($cmd);
  if ( $? != 0 ) {
    Rex::Logger::info( "Can't create upload archive. Command failed: $cmd",
      "error" );
    CORE::exit(1);
  }

  my $ua = LWP::UserAgent->new();
  $ua->env_proxy;

  my $overlord_server = $self->overlord;
  my $upload_url      = $overlord_server;
  $upload_url .= "/" if ( $upload_url !~ m/\/$/ );

  $upload_url .= "1.0/rex/$ref->{Name}/$ref->{Version}/upload";

  my $up_request = POST(
    $upload_url,
    Content_Type => 'form-data',
    Content      => [
      rexfile_archive     => [$tmp_file],
      rexfile_name        => $ref->{Name},
      rexfile_description => ( $ref->{Description} || "" ),
    ]
  );

  Rex::Logger::debug("Uploading rexfile to $upload_url.");
  my $up_res = $ua->request($up_request);

  if ( $up_res->code != 200 ) {
    Rex::Logger::info( "Uploading of Rexfile to your Overlord server failed.",
      "error" );
    $up_res->{_request}->{_content} = "replaced by debug output";
    Rex::Logger::debug( Dumper($up_res) );

    Rex::Logger::debug("Removing temporary file: $tmp_file.");
    CORE::unlink($tmp_file);
    CORE::exit(2);
  }

  Rex::Logger::info("$ref->{Name} ($ref->{Version}) successfully uploaded.");

  Rex::Logger::debug("Removing temporary file: $tmp_file.");
  CORE::unlink($tmp_file);
}

1;
