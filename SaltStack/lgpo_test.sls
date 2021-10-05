interactive_logon_text:
  lgpo.set:
   - computer_policy:
      legalnoticetext: 'This proves that Salt is working.'

update_gpo:
  cmd.run:
   - name: "gpupdate /force"

# This will update the local group policy to enable the legal notice text.  
# I used this to test that the salt config worked on test servers.   