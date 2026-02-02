
#------------------ Software ------------------


alias launcher='/opt/sidefx/launcher/bin/houdini_launcher'

#alias blender='flatpak run org.blender.Blender'

alias nuke='/home/tomas/Nuke16.0v4/Nuke16.0'
alias nukex='/home/tomas/Nuke16.0v4/Nuke16.0 --nukex'
alias nukeassist='/home/tomas/Nuke16.0v4/Nuke16.0 --nukeassist'
alias foundry='/home/tomas/FoundryLicensingUtility_8.1.6.AppImage'

alias katana='/home/tomas/Katana7.0v3/katana'

alias hl='houdini "$(ls -t | head -n1)"'
alias nul='nukex "$(ls -t ../NUKE/*.nknc | head -n 1)"'
alias nl='natron "$(ls -t ../NUKE/*.ntp | head -n 1)"'
alias nr='snap restart natron'
alias bl='blender "$(time ls -t ../BLEND/*.blend 2>/dev/null | head -n 1 || echo "")"'
#alias bl='blender "$(ls -t ../BLEND/*.blend | head -n 1)"'
#alias flamenco='./start-flamenco-workers.sh'
alias flamenco='./flamenco-3.6/flamenco-worker'

alias davinci='distrobox-enter -n rocky-resolve -- /opt/resolve/bin/resolve'

alias meshroom='/home/tomas/Meshroom-2023.3.0/Meshroom'
alias quixel='/home/tomas/Bridge.AppImage --no-sandbox'
#alias quixel='/home/tomas/Bridge.AppImage --no-sandbox --disable-gpu --disable-features=Vulkan'

#alias djv='/usr/local/DJV2/bin/djv'
#alias diff='/home/tomas/easy-diffusion/start.sh'
alias fspy='/home/tomas/fspy-1.0.3-x86_64.AppImage'
alias byplay='/home/tomas/Byplay-Desktop-2.0.11.AppImage'
alias makehuman='python3 /home/tomas/makehuman/makehuman/makehuman.py'

alias cascadeur='/media/NAS/ToMarsLabs/data/Library/software/cascadeur-linux/cascadeur'

alias ai='/home/tomas/ollama.py'
alias comfy='/home/tomas/ComfyUI/comfy_launcher.sh'
alias comfyenv='source /home/tomas/ComfyUI/.venv/bin/activate'

#----------------- Custom Script -------------------

alias tomp4='/home/tomas/image_to_mp4.sh'
alias toimage='/home/tomas/video_to_image.sh'
alias tovideo='/home/tomas/image_to_video.sh'
alias stich='/home/tomas/stich.sh'
alias sortvideos='/home/tomas/sort_videos_by_resolution.sh'
alias pdfmerge='/home/tomas/pdfmerge.sh'
alias underscored='/home/tomas/underscored'

alias server='/home/tomas/server_ssh.sh && exit'
alias mares='/home/tomas/mares_ssh.sh && exit'
alias nas='/home/tomas/nas.sh && exit'

#-------------------- Linux Utilities --------------------

alias bootloader='sudo dpkg-reconfigure sddm'
alias gogh='bash -c  "$(wget -qO- https://git.io/vQgMr)" '
alias statusremote='systemctl --user status gnome-remote-desktop.service'
alias restartremote='systemctl --user restart gnome-remote-desktop.service'

