/* window.vala
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


[GtkTemplate (ui = "/org/droidian/Settings/encryption_passphrase.ui")]
public class DroidianSettings.PassphraseDialog : Adw.Window {

    [Description(nick = "change_passphrase", blurb = "Whether this is a change password dialog")]
    public bool change_passphrase { get; construct; }

    [Description(nick = "match", blurb = "Whether the passphrase match")]
    public bool match { get; private set; default = false; }

    [Description(nick = "passphrase", blurb = "The chosen passphrase")]
    public string passphrase {
        get {
            return this.passphrase_entry.text;
        }
    }

    [Description(nick = "response", blurb = "Signal fired when the user closes the dialog")]
    public signal void response (bool ok);

    [GtkChild]
    unowned Gtk.Button encryption_cancel_button;

    [GtkChild]
    unowned Gtk.Button encryption_apply_button;

    [GtkChild]
    unowned Gtk.Label passphrase_new_label;

    [GtkChild]
    unowned Gtk.PasswordEntry passphrase_current_entry;

    [GtkChild]
    unowned Gtk.PasswordEntry passphrase_entry;

    [GtkChild]
    unowned Gtk.PasswordEntry passphrase_confirm_entry;

    public PassphraseDialog (bool change_passphrase = false) {
        Object (change_passphrase: change_passphrase);

        /* Show passphrase_current_entry only on change password dialog */
        this.bind_property ("change_passphrase", this.passphrase_current_entry,
                            "visible", BindingFlags.DEFAULT | BindingFlags.SYNC_CREATE);

        this.bind_property ("change_passphrase", this.passphrase_new_label,
                            "visible", BindingFlags.DEFAULT | BindingFlags.SYNC_CREATE | BindingFlags.INVERT_BOOLEAN);

        this.bind_property ("match", this.encryption_apply_button,
                            "sensitive", BindingFlags.DEFAULT | BindingFlags.SYNC_CREATE);

        this.passphrase_entry.changed.connect (this.on_passphrase_changed);
        this.passphrase_confirm_entry.changed.connect (this.on_passphrase_changed);

        this.encryption_cancel_button.clicked.connect (this.on_dialog_action);
        this.encryption_apply_button.clicked.connect (this.on_dialog_action);

        this.close_request.connect (this.on_close_request);
    }

    private void on_passphrase_changed () {
        this.match = ((this.change_passphrase ? this.passphrase_current_entry.text.length > 0 : true) &&
                      this.passphrase_entry.text.length > 0 &&
                      this.passphrase_entry.text == this.passphrase_confirm_entry.text);
    }

    private void on_dialog_action (Gtk.Button button) {
        this.response (button == this.encryption_apply_button);
        this.hide ();
    }

    private bool on_close_request (Gtk.Window window) {
        this.response (false);
        this.hide ();

        return true;
    }
}

[GtkTemplate (ui = "/org/droidian/Settings/encryption_page.ui")]
public class DroidianSettings.EncryptionPage : Gtk.Box {
	[GtkChild]
	unowned Gtk.Button encrypt_button;

	[GtkChild]
	unowned Gtk.Button change_passphrase_button;

	[GtkChild]
	unowned Adw.PreferencesGroup encryption_preferences;

    [GtkChild]
    unowned Adw.ActionRow encryption_actionrow;

	[GtkChild]
	unowned Gtk.Spinner encryption_spinner;

	[GtkChild]
	unowned Gtk.Image encryption_icon;

    DroidianSettings.PassphraseDialog passphrase_dialog;

    DroidianSettings.EncryptionService encryption_service;

	public EncryptionPage () {
		Object ();

        /* Create EncryptionService object */
        this.encryption_service = new DroidianSettings.EncryptionService ();

        /* Create passphrase dialog */
        this.passphrase_dialog = new DroidianSettings.PassphraseDialog ();

        /* Bind page visibility to passphrase_dialog's */
        this.bind_property ("sensitive", this.passphrase_dialog, "visible",
                            BindingFlags.INVERT_BOOLEAN);

        /* Add the header suffix */
		this.encryption_preferences.header_suffix = this.encrypt_button;


		this.encryption_service.notify["status"].connect (this.on_service_status_notify);

		/* Trigger initial */
		this.on_service_status_notify ();

	}

	[GtkCallback]
	private void on_encrypt_action_clicked (Gtk.Button button) {
	    bool is_change_passphrase = (button == this.change_passphrase_button);
        this.passphrase_dialog = new DroidianSettings.PassphraseDialog (is_change_passphrase);

        if (!is_change_passphrase) {
            this.passphrase_dialog.response.connect (this.on_encrypt_dialog_response);
        } else {
            this.passphrase_dialog.response.connect (this.on_encrypt_change_passphrase_response);
        }

        this.passphrase_dialog.present ();
	}

    private void on_encrypt_dialog_response (bool ok) {
        message ("Encryption response %i", (int)ok);

        if (ok) {
            /* Should start encryption */
            this.encryption_service.start_encryption.begin (this.passphrase_dialog.passphrase, null);
        }

        this.passphrase_dialog.destroy ();
    }

    private void on_encrypt_change_passphrase_response (bool ok) {
        message ("Change passphrase response %i", (int)ok);

        this.passphrase_dialog.destroy ();
    }

    private void on_service_status_notify () {
        string status_string;
        string? icon = null;
        bool show_spinner = false;
        bool encrypt_button_sensitive = false;

        switch (this.encryption_service.status) {
            case DroidianSettings.EncryptionServiceStatus.UNSUPPORTED:
            default:
                status_string = "Encryption is not supported.";
                break;
            case DroidianSettings.EncryptionServiceStatus.UNCONFIGURED:
                status_string = "Encryption is not configured.";
                encrypt_button_sensitive = true;
                break;
            case DroidianSettings.EncryptionServiceStatus.CONFIGURING:
                status_string = "Encryption is being configured, please wait.";
                show_spinner = true;
                break;
            case DroidianSettings.EncryptionServiceStatus.CONFIGURED:
                status_string = "Encryption has been configured.\n\nPlease reboot to start encrypting your device.";
                icon = "system-run-symbolic";
                break;
            case DroidianSettings.EncryptionServiceStatus.ENCRYPTING:
                status_string = "Droidian is encrypting your device.";
                show_spinner = true;
                break;
            case DroidianSettings.EncryptionServiceStatus.ENCRYPTED:
                status_string = "Your device is encrypted.";
                icon = "emblem-ok-symbolic";
                break;
            case DroidianSettings.EncryptionServiceStatus.FAILED:
                status_string = "Something wrong happened during device encryption.";
                icon = "computer-fail-symbolic";
                break;
        }

        /* We can't bind spinner and icon together because it might happen that they both need to be hidden */
        this.encryption_spinner.hide ();
        this.encryption_icon.hide ();

        this.encrypt_button.sensitive = encrypt_button_sensitive;

        if (show_spinner) {
            this.encryption_spinner.show ();
        } else if (icon != null) {
            this.encryption_icon.icon_name = icon;
            this.encryption_icon.show ();
        }

        this.encryption_actionrow.title = status_string;

    }

}
