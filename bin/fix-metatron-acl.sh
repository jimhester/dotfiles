#!/bin/bash
# Re-apply ACLs on ~/.metatron after metatron agent refreshes certs.
# Metatron creates new files with 0600 that lose inherited ACLs.
# Called by launchd WatchPaths on any change to ~/.metatron/certificates/.

AGENT_USER="claude-agent"
METATRON_DIR="$HOME/.metatron"

chmod -R +a "${AGENT_USER} allow read,execute,list,search,file_inherit,directory_inherit" "$METATRON_DIR" 2>/dev/null
