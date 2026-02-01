#!/usr/bin/env python3
"""
Simple Bluetooth Agent for auto-accepting pairing requests.
This agent uses the BlueZ D-Bus API to handle pairing.

Usage: python3 bluetooth-agent.py &
"""

import dbus
import dbus.service
import dbus.mainloop.glib
from gi.repository import GLib
import sys

AGENT_INTERFACE = "org.bluez.Agent1"
AGENT_PATH = "/org/bluez/AutoAgent"

class AutoAcceptAgent(dbus.service.Object):
    """Bluetooth agent that auto-accepts all pairing requests."""
    
    exit_on_release = True

    def set_exit_on_release(self, exit_on_release):
        self.exit_on_release = exit_on_release

    @dbus.service.method(AGENT_INTERFACE, in_signature="", out_signature="")
    def Release(self):
        print("[Agent] Released")
        if self.exit_on_release:
            mainloop.quit()

    @dbus.service.method(AGENT_INTERFACE, in_signature="os", out_signature="")
    def AuthorizeService(self, device, uuid):
        print(f"[Agent] AuthorizeService: {device} {uuid}")
        return

    @dbus.service.method(AGENT_INTERFACE, in_signature="o", out_signature="s")
    def RequestPinCode(self, device):
        print(f"[Agent] RequestPinCode: {device}")
        return "0000"

    @dbus.service.method(AGENT_INTERFACE, in_signature="o", out_signature="u")
    def RequestPasskey(self, device):
        print(f"[Agent] RequestPasskey: {device}")
        return dbus.UInt32(0)

    @dbus.service.method(AGENT_INTERFACE, in_signature="ouq", out_signature="")
    def DisplayPasskey(self, device, passkey, entered):
        print(f"[Agent] DisplayPasskey: {device} {passkey:06d} entered {entered}")

    @dbus.service.method(AGENT_INTERFACE, in_signature="os", out_signature="")
    def DisplayPinCode(self, device, pincode):
        print(f"[Agent] DisplayPinCode: {device} {pincode}")

    @dbus.service.method(AGENT_INTERFACE, in_signature="ou", out_signature="")
    def RequestConfirmation(self, device, passkey):
        print(f"[Agent] RequestConfirmation: {device} {passkey:06d}")
        # Auto-confirm
        return

    @dbus.service.method(AGENT_INTERFACE, in_signature="o", out_signature="")
    def RequestAuthorization(self, device):
        print(f"[Agent] RequestAuthorization: {device}")
        # Auto-authorize
        return

    @dbus.service.method(AGENT_INTERFACE, in_signature="", out_signature="")
    def Cancel(self):
        print("[Agent] Cancel")


def main():
    global mainloop
    
    dbus.mainloop.glib.DBusGMainLoop(set_as_default=True)
    
    bus = dbus.SystemBus()
    
    # Create agent
    agent = AutoAcceptAgent(bus, AGENT_PATH)
    
    # Get AgentManager
    manager = dbus.Interface(
        bus.get_object("org.bluez", "/org/bluez"),
        "org.bluez.AgentManager1"
    )
    
    # Register agent with NoInputNoOutput capability (auto-accept)
    try:
        manager.RegisterAgent(AGENT_PATH, "NoInputNoOutput")
        print("[Agent] Agent registered")
    except dbus.exceptions.DBusException as e:
        print(f"[Agent] Failed to register agent: {e}")
        sys.exit(1)
    
    # Make this the default agent
    try:
        manager.RequestDefaultAgent(AGENT_PATH)
        print("[Agent] Default agent requested")
    except dbus.exceptions.DBusException as e:
        print(f"[Agent] Failed to set default agent: {e}")
    
    print("[Agent] Bluetooth agent running. Press Ctrl+C to exit.")
    
    mainloop = GLib.MainLoop()
    try:
        mainloop.run()
    except KeyboardInterrupt:
        pass
    finally:
        try:
            manager.UnregisterAgent(AGENT_PATH)
            print("[Agent] Agent unregistered")
        except:
            pass


if __name__ == "__main__":
    main()
