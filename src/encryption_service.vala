/* encryption_service.vala
 *
 * Copyright 2022 Eugenio Paolantonio (g7)
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

public enum DroidianSettings.EncryptionServiceStatus {
    UNKNOWN = 0,
    UNSUPPORTED,
    UNCONFIGURED,
    CONFIGURING,
    CONFIGURED,
    ENCRYPTING,
    ENCRYPTED,
    FAILED,
}


[DBus (name = "org.droidian.EncryptionService.Encryption")]
private interface DroidianSettings.EncryptionServiceInterface : Object {
    public abstract async void Start (string passphrase) throws GLib.Error;
    public abstract async void RefreshStatus () throws GLib.Error;

    public abstract DroidianSettings.EncryptionServiceStatus Status { get; }
}

public class DroidianSettings.EncryptionService : Object {

    [Description(nick = "status", blurb = "The encryption status")]
    public DroidianSettings.EncryptionServiceStatus status {
        get;
        private set;
        default = DroidianSettings.EncryptionServiceStatus.UNSUPPORTED;
    }

    private DroidianSettings.EncryptionServiceInterface iface = null;

    private uint status_timeout_source;

    public EncryptionService () {
        Object ();

        Bus.get_proxy.begin<DroidianSettings.EncryptionServiceInterface> (
            BusType.SYSTEM, "org.droidian.EncryptionService",
            "/Encryption", DBusProxyFlags.NONE,
            null, (obj, res) => {
                message ("Got proxy!");
                this.iface = Bus.get_proxy.end (res);

                /* Refresh status every 30 seconds */
                this.status_timeout_source = GLib.Timeout.add_seconds (30, this.refresh_status);
                this.notify["status"].connect (on_status_changed);

                /* Do initial sync */
                this.refresh_status ();
                this.status = this.iface.Status;

                /* Replace this with a binding once vala supports doing that on dbus props */
                ((GLib.DBusProxy) this.iface).g_properties_changed.connect ((changed, invalid) => {
                    Variant? val;
                    if ((val = changed.lookup_value ("Status", VariantType.INT32)) != null) {
                        this.status = (DroidianSettings.EncryptionServiceStatus) val;
                    }
                });
            });
    }

    private bool refresh_status () {
        message ("Refresh timeout");

        this.iface.RefreshStatus.begin (null);

        return GLib.Source.CONTINUE;
    }

    private void on_status_changed () {
        switch (this.status) {
            case DroidianSettings.EncryptionServiceStatus.UNKNOWN:
            case DroidianSettings.EncryptionServiceStatus.UNCONFIGURED:
            case DroidianSettings.EncryptionServiceStatus.CONFIGURING:
            case DroidianSettings.EncryptionServiceStatus.ENCRYPTING:
                /* Non-permanent status, continue */
                break;
            default:
                /* Permanent status, drop the timeout */
                GLib.Source.remove (this.status_timeout_source);
                break;
        }
    }

    public async void synchronize_status () {
        yield this.iface.RefreshStatus ();
    }

    public async void start_encryption (string passphrase) {
        try {
            yield this.iface.Start (passphrase);
        } catch (GLib.Error error) {
            warning ("Got error %s during EncryptionServiceInterface.Start () call\n", error.message);
            /* FIXME: check the error domain/code instead! */
            if (!error.message.contains("Not authorized"))
                this.status = DroidianSettings.EncryptionServiceStatus.FAILED;
        }

    }
}
