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


[GtkTemplate (ui = "/org/droidian/Settings/settings.ui")]
public class DroidianSettings.Window : Adw.ApplicationWindow {
	[GtkChild]
	unowned Adw.Leaflet leaflet;

	[GtkChild]
	unowned Gtk.Box setting_box;

	[GtkChild]
	unowned Adw.Bin encryption_page_bin;

	public Window (Adw.Application app) {
		Object (application: app);

		var encryption_page = new DroidianSettings.EncryptionPage ();
		this.encryption_page_bin.child = encryption_page;

		/* Navigate forward */
		this.leaflet.navigate (Adw.NavigationDirection.FORWARD);
	}

	[GtkCallback]
	private void on_back_button_clicked (Gtk.Button button) {
        this.leaflet.navigate (Adw.NavigationDirection.BACK);
	}

	[GtkCallback]
	private void on_stack_notify_visible_changed (GLib.Object obj, GLib.ParamSpec spec) {
	    this.leaflet.navigate (Adw.NavigationDirection.FORWARD);
	}
}
