public class Widgets.SourceButton : Gtk.Button {
    public int64 temp_id_mapping { get; set; default = 0; }
    public string primary_text { get; construct; }
    public string source { get; construct; }
    public string icon_name { get; construct; }
    public string key { get; construct; }

    private Gtk.Revealer loading_revealer;

    public bool loading {
        set {
            loading_revealer.reveal_child = value;
        }

        get {
            return loading_revealer.reveal_child;
        }
    }

    public SourceButton (string primary_text, string source, string icon_name, string key="") {
        Object (
            primary_text: primary_text,
            source: source,
            icon_name: icon_name
        );
    }

    construct {
        get_style_context ().remove_class ("button");
        get_style_context ().add_class ("flat");
        get_style_context ().add_class ("menuitem");
        get_style_context ().add_class ("no-border");
        get_style_context ().add_class ("source-button");
        can_focus = false;
        tooltip_text = source;

        var icon_image = new Gtk.Image ();
        icon_image.valign = Gtk.Align.CENTER;
        icon_image.halign = Gtk.Align.CENTER;
        icon_image.pixel_size = 16;
        icon_image.gicon = new ThemedIcon (icon_name);

        var primary_text_label = new Gtk.Label (primary_text);
        primary_text_label.ellipsize = Pango.EllipsizeMode.END;
        primary_text_label.halign = Gtk.Align.START;
        primary_text_label.xalign = 0;

        var source_label = new Gtk.Label (source);
        source_label.halign = Gtk.Align.START;
        source_label.ellipsize = Pango.EllipsizeMode.END;
        source_label.get_style_context ().add_class ("small-label");
        source_label.get_style_context ().add_class ("dim-label");

        var spinner_loading = new Gtk.Spinner ();
        spinner_loading.valign = Gtk.Align.CENTER;
        spinner_loading.halign = Gtk.Align.END;
        spinner_loading.hexpand = true;
        spinner_loading.active = true;
        spinner_loading.start ();
        spinner_loading.margin_end = 6;

        loading_revealer = new Gtk.Revealer ();
        loading_revealer.transition_type = Gtk.RevealerTransitionType.CROSSFADE;
        loading_revealer.add (spinner_loading);

        var grid = new Gtk.Grid ();
        grid.column_spacing = 6;
        grid.row_spacing = 3;
        grid.attach (icon_image,         0, 0, 1, 1);
        grid.attach (primary_text_label, 1, 0, 1, 1);
        grid.attach (source_label,       1, 1, 1, 1);
        grid.attach (loading_revealer,    2, 0, 2, 2);

        add (grid);

        Planner.todoist.project_added_started.connect ((id) => {
            sensitive = false;
            if (temp_id_mapping == id) {
                loading = true;
            }
        });

        Planner.todoist.project_added_completed.connect ((id, project_id) => {
            sensitive = true;
            if (temp_id_mapping == id) {
                temp_id_mapping = 0;
                loading = false;

                Timeout.add (250, () => {
                    Planner.event_bus.pane_selected (PaneType.PROJECT, project_id.to_string ());
                    Planner.event_bus.edit_project (project_id);
                    return GLib.Source.REMOVE;
                });
            }
        });

        Planner.todoist.project_added_error.connect ((id, error_code, error_message) => {
            sensitive = true;
            if (temp_id_mapping == id) {
                temp_id_mapping = 0;
                loading = false;
            }
            
            if (error_code != 0) {
                Planner.notifications.send_notification (error_message, NotificationStyle.ERROR);
            }
        });
    }
}