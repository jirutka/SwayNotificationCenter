namespace SwayNotificatonCenter {
    [GtkTemplate (ui = "/org/erikreider/sway-notification-center/notiWindow/notiWindow.ui")]
    public class NotiWindow : Gtk.ApplicationWindow {

        [GtkChild]
        unowned Gtk.Viewport viewport;
        [GtkChild]
        unowned Gtk.Box box;

        private DBusInit dbusInit;

        private bool list_reverse = false;

        private double last_upper = 0;

        public NotiWindow (DBusInit dbusInit) {
            this.dbusInit = dbusInit;

            GtkLayerShell.init_for_window (this);
            GtkLayerShell.set_layer (this, GtkLayerShell.Layer.OVERLAY);
            switch (dbusInit.configModel._positionX) {
                case Positions.left:
                    GtkLayerShell.set_anchor (this, GtkLayerShell.Edge.LEFT, true);
                    break;
                default:
                    GtkLayerShell.set_anchor (this, GtkLayerShell.Edge.RIGHT, true);
                    break;
            }
            switch (dbusInit.configModel._positionY) {
                case Positions.bottom:
                    GtkLayerShell.set_anchor (this, GtkLayerShell.Edge.BOTTOM, true);
                    list_reverse = true;
                    break;
                default:
                    GtkLayerShell.set_anchor (this, GtkLayerShell.Edge.TOP, true);
                    break;
            }
            viewport.size_allocate.connect (() => size_alloc (list_reverse));
        }

        private void size_alloc (bool reverse) {
            var adj = viewport.vadjustment;
            double upper = adj.get_upper ();
            if (last_upper < upper) {
                scroll_to_start (reverse);
            }
            last_upper = upper;
        }

        private void scroll_to_start (bool reverse) {
            var adj = viewport.vadjustment;
            var val = (reverse ? adj.get_upper () : adj.get_lower ());
            adj.set_value (val);
        }

        public void change_visibility (bool value) {
            this.set_visible (value);
            if (!value) close_all_notifications ();
        }

        public void close_all_notifications () {
            foreach (var w in box.get_children ()) {
                box.remove (w);
            }
        }

        private void remove_noti (Notification noti) {
            if (box.get_children ().index (noti) >= 0) {
                box.remove (noti);
            }
            if (box.get_children ().length () == 0) this.hide ();
        }

        public void add_notification (NotifyParams param, NotiDaemon notiDaemon) {
            var noti = new Notification.timed (param, notiDaemon, remove_noti);

            if (list_reverse) {
                box.pack_start (noti);
            } else {
                box.pack_end (noti);
            }
            this.grab_focus ();
            this.show ();
            scroll_to_start (list_reverse);
        }

        public void close_notification (uint32 id) {
            foreach (var w in box.get_children ()) {
                var noti = (Notification) w;
                if (noti != null && noti.param.applied_id == id) {
                    remove_noti (noti);
                    break;
                }
            }
        }
    }
}
