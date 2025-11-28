_:

{
  programs.git = {
    signing = {
      signByDefault = true;
      key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINTuvuCDtmFBcTEkfOyx1NlUJZPcCJ76cChOt8ACBGKG";
    };

    settings = {
      user = {
        name = "Matt Robenolt";
        email = "matt@ydekproductions.com";
      };

      url."git@github.com:" = {
        insteadOf = "https://github.com";
      };

      http = {
        cookiefile = "~/.gitcookies";
      };

      gpg = {
        format = "ssh";
        ssh.program = "/Applications/1Password.app/Contents/MacOS/op-ssh-sign";
      };
    };
  };
}
