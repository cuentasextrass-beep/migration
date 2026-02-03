#!/usr/bin/env python3
import subprocess
import time
import signal
import sys
import os
from threading import Thread

class ServiceManager:
    def __init__(self):
        self.ollama_process = None
        self.docker_container = "open-webui"
        self.webui_url = "http://localhost:8080"
        self.services_started = False
        self.firefox_process = None
        self.nvidia_terminal = None
        
    def log(self, message):
        """Print timestamped log message"""
        timestamp = time.strftime("%H:%M:%S")
        print(f"[{timestamp}] {message}")
    
    def check_ollama_running(self):
        """Check if Ollama is already running"""
        try:
            result = subprocess.run(
                ["pgrep", "-f", "ollama serve"],
                capture_output=True,
                text=True
            )
            return result.returncode == 0
        except:
            return False
    
    def check_docker_running(self):
        """Check if Docker container is running"""
        try:
            result = subprocess.run(
                ["docker", "ps", "--filter", f"name={self.docker_container}", "--format", "{{.Names}}"],
                capture_output=True,
                text=True
            )
            return self.docker_container in result.stdout
        except:
            return False
    
    def start_ollama(self):
        """Start Ollama service"""
        if self.check_ollama_running():
            self.log("✓ Ollama is already running")
            return True
        
        self.log("Starting Ollama service...")
        try:
            # Start ollama serve in background
            self.ollama_process = subprocess.Popen(
                ["ollama", "serve"],
                stdout=subprocess.DEVNULL,
                stderr=subprocess.DEVNULL,
                preexec_fn=os.setpgrp  # Create new process group
            )
            
            # Wait for Ollama to be ready
            max_retries = 30
            for i in range(max_retries):
                try:
                    result = subprocess.run(
                        ["curl", "-s", "http://localhost:11434/api/tags"],
                        capture_output=True,
                        timeout=1
                    )
                    if result.returncode == 0:
                        self.log("✓ Ollama service started successfully")
                        return True
                except:
                    pass
                time.sleep(1)
            
            self.log("✗ Ollama failed to start")
            return False
            
        except Exception as e:
            self.log(f"✗ Error starting Ollama: {e}")
            return False
    
    def start_docker(self):
        """Start Docker WebUI container"""
        if self.check_docker_running():
            self.log("✓ Docker WebUI is already running")
            return True
        
        self.log("Starting Docker WebUI container...")
        try:
            result = subprocess.run(
                ["sudo", "docker", "start", self.docker_container],
                capture_output=True,
                text=True
            )
            
            if result.returncode == 0:
                # Wait for WebUI to be ready
                max_retries = 30
                for i in range(max_retries):
                    try:
                        result = subprocess.run(
                            ["curl", "-s", "-o", "/dev/null", "-w", "%{http_code}", self.webui_url],
                            capture_output=True,
                            text=True,
                            timeout=1
                        )
                        if result.stdout.strip() in ["200", "404", "302"]:
                            self.log("✓ Docker WebUI started successfully")
                            return True
                    except:
                        pass
                    time.sleep(1)
                
                self.log("✗ Docker WebUI failed to respond")
                return False
            else:
                self.log(f"✗ Failed to start Docker container: {result.stderr}")
                return False
                
        except Exception as e:
            self.log(f"✗ Error starting Docker: {e}")
            return False
    
    def open_webui(self):
        """Open WebUI in a new Firefox window"""
        self.log(f"Opening Firefox window at {self.webui_url}")
        time.sleep(2)  # Give services a moment to stabilize
        
        try:
            # Open Firefox in a new window
            self.firefox_process = subprocess.Popen(
                ["firefox", "--new-window", self.webui_url],
                stdout=subprocess.DEVNULL,
                stderr=subprocess.DEVNULL
            )
            self.log("✓ Firefox window opened")
            
            # Monitor the Firefox process
            self.firefox_process.wait()
            self.log("Firefox window closed")
            
        except FileNotFoundError:
            self.log("✗ Firefox not found. Please install Firefox or use 'firefox-esr'")
            self.log("Keeping services running. Press Ctrl+C to stop.")
            try:
                while True:
                    time.sleep(1)
            except KeyboardInterrupt:
                pass
        except Exception as e:
            self.log(f"✗ Error opening Firefox: {e}")
            self.log("Keeping services running. Press Ctrl+C to stop.")
            try:
                while True:
                    time.sleep(1)
            except KeyboardInterrupt:
                pass
    
    def open_nvidia_monitor(self):
        """Open a new terminal with nvidia-smi monitoring"""
        self.log("Opening NVIDIA monitor terminal...")
        
        try:
            # Try different terminal emulators in order of preference
            terminals = [
                # GNOME Terminal with bright green
                ["gnome-terminal", "--", "bash", "-c", 
                 "printf '\\033]11;black\\007\\033]10;#00FF00\\007'; watch -n 0.5 nvidia-smi; exec bash"],
                # xterm with bright green
                ["xterm", "-bg", "black", "-fg", "#00FF00", "-e", 
                 "watch -n 0.5 nvidia-smi"],
                # Konsole (KDE) with bright green
                ["konsole", "--background-color", "black", "--foreground-color", "#00FF00", 
                 "-e", "watch -n 0.5 nvidia-smi"],
                # xfce4-terminal with bright green
                ["xfce4-terminal", "--color-bg", "black", "--color-text", "#00FF00", 
                 "-e", "watch -n 0.5 nvidia-smi"],
                # Fallback - just try to open any terminal
                ["x-terminal-emulator", "-e", "watch -n 0.5 nvidia-smi"]
            ]
            
            for terminal_cmd in terminals:
                try:
                    self.nvidia_terminal = subprocess.Popen(
                        terminal_cmd,
                        stdout=subprocess.DEVNULL,
                        stderr=subprocess.DEVNULL
                    )
                    self.log(f"✓ NVIDIA monitor terminal opened ({terminal_cmd[0]})")
                    return True
                except FileNotFoundError:
                    continue
            
            self.log("✗ No suitable terminal emulator found")
            return False
            
        except Exception as e:
            self.log(f"✗ Error opening NVIDIA terminal: {e}")
            return False
    
    def stop_ollama(self):
        """Stop Ollama service"""
        self.log("Stopping Ollama service...")
        try:
            if self.ollama_process:
                # Kill the process group
                os.killpg(os.getpgid(self.ollama_process.pid), signal.SIGTERM)
                self.ollama_process.wait(timeout=5)
            else:
                # If we didn't start it, try to kill by name
                subprocess.run(["pkill", "-f", "ollama serve"], check=False)
            
            self.log("✓ Ollama service stopped")
        except Exception as e:
            self.log(f"! Error stopping Ollama: {e}")
    
    def stop_docker(self):
        """Stop Docker WebUI container"""
        self.log("Stopping Docker WebUI container...")
        try:
            result = subprocess.run(
                ["sudo", "docker", "stop", self.docker_container],
                capture_output=True,
                text=True,
                timeout=10
            )
            if result.returncode == 0:
                self.log("✓ Docker WebUI stopped")
            else:
                self.log(f"! Error stopping Docker: {result.stderr}")
        except Exception as e:
            self.log(f"! Error stopping Docker: {e}")
    
    def cleanup(self, signum=None, frame=None):
        """Cleanup function to stop all services"""
        if not self.services_started:
            return
            
        print("\n" + "="*50)
        self.log("Shutting down services...")
        print("="*50)
        
        # Close NVIDIA terminal if it's still running
        if self.nvidia_terminal and self.nvidia_terminal.poll() is None:
            try:
                self.nvidia_terminal.terminate()
                self.nvidia_terminal.wait(timeout=2)
            except:
                try:
                    self.nvidia_terminal.kill()
                except:
                    pass
        
        # Close Firefox if it's still running
        if self.firefox_process and self.firefox_process.poll() is None:
            try:
                self.firefox_process.terminate()
                self.firefox_process.wait(timeout=5)
            except:
                pass
        
        self.stop_docker()
        self.stop_ollama()
        
        self.log("All services stopped. Goodbye!")
        sys.exit(0)
    
    def run(self):
        """Main run function"""
        # Set up signal handlers for cleanup
        signal.signal(signal.SIGINT, self.cleanup)
        signal.signal(signal.SIGTERM, self.cleanup)
        
        print("="*50)
        self.log("Ollama WebUI Launcher")
        print("="*50)
        
        # Start services
        if not self.start_ollama():
            self.log("Failed to start Ollama. Exiting.")
            sys.exit(1)
        
        if not self.start_docker():
            self.log("Failed to start Docker WebUI. Cleaning up...")
            self.stop_ollama()
            sys.exit(1)
        
        self.services_started = True
        
        print("="*50)
        self.log("All services running!")
        self.log(f"WebUI available at: {self.webui_url}")
        print("="*50 + "\n")
        
        # Open NVIDIA monitor in separate terminal
        self.open_nvidia_monitor()
        
        # Small delay before opening Firefox
        time.sleep(1)
        
        self.log("Opening Firefox window...")
        self.log("Close Firefox window or press Ctrl+C to stop all services")
        print("="*50 + "\n")
        
        # Open Firefox window (this will block until window is closed)
        self.open_webui()
        
        # If we get here, Firefox was closed
        self.cleanup()

if __name__ == "__main__":
    manager = ServiceManager()
    manager.run()