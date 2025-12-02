_:

{
  # Disable unwanted macOS services
  # These will persist across macOS updates and be managed by nix-darwin

  # Create a launchd agent that disables Apple's bloat services on login
  launchd.user.agents.disable-macos-bloat = {
    script = ''
      # Get the user ID (use USER_ID since UID is readonly in bash)
      USER_ID=$(id -u)

      # Function to disable and kill a service
      disable_service() {
        local service=$1
        local process_name=$2

        # If no process name provided, derive it from service name
        if [ -z "$process_name" ]; then
          process_name=$(echo $service | sed 's/.*\.//')
        fi

        # Disable the service (prevents it from starting on next boot)
        /bin/launchctl disable gui/$USER_ID/$service 2>/dev/null || true

        # Kill the running process directly
        /usr/bin/pkill -9 "$process_name" 2>/dev/null || true

        # Bootout from launchd
        /bin/launchctl bootout gui/$USER_ID/$service 2>/dev/null || true
      }

      # Disable Siri services
      disable_service com.apple.siriknowledged
      disable_service com.apple.siriinferenced
      disable_service com.apple.sirittsd
      disable_service com.apple.siriactionsd

      # Disable Analytics
      disable_service com.apple.analyticsagent
      disable_service com.apple.geoanalyticsd
      disable_service com.apple.inputanalyticsd

      # Disable Handoff/Continuity
      disable_service com.apple.rapportd-user

      # Disable Media Analysis
      disable_service com.apple.mediaanalysisd
      disable_service com.apple.photoanalysisd

      # Disable Continuity Camera
      disable_service com.apple.cmio.ContinuityCaptureAgent

      # Disable Game Center
      disable_service com.apple.gamed
      disable_service com.apple.GameController.gamecontrolleragentd
      disable_service com.apple.GamePolicyAgent
      disable_service com.apple.sociallayerd

      # Disable Screen Time
      disable_service com.apple.ScreenTimeAgent

      # Disable Spotlight (you use Raycast instead)
      disable_service com.apple.corespotlightd
      disable_service com.apple.spotlightknowledged
      disable_service com.apple.Spotlight

      # Disable Apple Intelligence
      disable_service com.apple.privatecloudcomputed
    '';

    serviceConfig = {
      RunAtLoad = true;
      ProcessType = "Background";
    };
  };
}
