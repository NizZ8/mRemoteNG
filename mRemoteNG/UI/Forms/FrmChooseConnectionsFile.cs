using System;
using System.Collections.Generic;
using System.Drawing;
using System.Globalization;
using System.Linq;
using System.Runtime.Versioning;
using System.Windows.Forms;
using mRemoteNG.Connection;
using mRemoteNG.Themes;

namespace mRemoteNG.UI.Forms
{
    /// <summary>
    /// Presented at startup when more than one <c>confCons.xml</c> is found across
    /// the well-known locations (installed, portable, legacy). Lets the user pick
    /// which one to load, with "newest by mtime" pre-selected.
    /// </summary>
    [SupportedOSPlatform("windows")]
    public sealed class FrmChooseConnectionsFile : Form
    {
        private readonly ListView _list = new();
        private readonly CheckBox _rememberBox = new();
        private readonly Button _okButton = new();
        private readonly Button _cancelButton = new();
        private readonly Label _header = new();

        private readonly IReadOnlyList<ConnectionsFileResolver.Candidate> _candidates;

        public ConnectionsFileResolver.Candidate? Chosen { get; private set; }
        public bool RememberChoice => _rememberBox.Checked;

        public FrmChooseConnectionsFile(IReadOnlyList<ConnectionsFileResolver.Candidate> candidates,
                                        ConnectionsFileResolver.Candidate? suggested)
        {
            _candidates = candidates ?? throw new ArgumentNullException(nameof(candidates));
            BuildForm(suggested);
            ApplyTheme();
        }

        private void BuildForm(ConnectionsFileResolver.Candidate? suggested)
        {
            Text = "mRemoteNG — choose connections file";
            FormBorderStyle = FormBorderStyle.Sizable;
            MinimizeBox = false;
            MaximizeBox = true;
            ShowInTaskbar = true;
            StartPosition = FormStartPosition.CenterScreen;
            MinimumSize = new Size(720, 360);
            Size = new Size(860, 420);
            KeyPreview = true;

            _header.Text =
                "Multiple connections files were found on this machine. Pick the one to load " +
                "(newest first is pre-selected). Your choice is persisted when \"Remember\" is " +
                "checked so this dialog will not appear again.";
            _header.Dock = DockStyle.Top;
            _header.AutoSize = false;
            _header.Height = 52;
            _header.Padding = new Padding(12, 12, 12, 4);
            _header.TextAlign = ContentAlignment.TopLeft;

            _list.View = View.Details;
            _list.FullRowSelect = true;
            _list.MultiSelect = false;
            _list.HideSelection = false;
            _list.Dock = DockStyle.Fill;
            _list.Columns.Add("Location", 190);
            _list.Columns.Add("Path", 380);
            _list.Columns.Add("Last modified", 150);
            _list.Columns.Add("Size", 90);

            foreach (ConnectionsFileResolver.Candidate c in _candidates)
            {
                ListViewItem row = new(c.Label);
                row.SubItems.Add(c.Path);
                row.SubItems.Add(c.LastWriteTimeUtc.ToLocalTime().ToString("yyyy-MM-dd HH:mm", CultureInfo.CurrentCulture));
                row.SubItems.Add(FormatSize(c.Size));
                row.Tag = c;
                if (suggested is not null && string.Equals(c.Path, suggested.Path, StringComparison.OrdinalIgnoreCase))
                    row.Selected = true;
                _list.Items.Add(row);
            }

            if (_list.SelectedItems.Count == 0 && _list.Items.Count > 0)
                _list.Items[0].Selected = true;

            _list.DoubleClick += (_, _) => AcceptSelection();

            _rememberBox.Text = "Remember this choice";
            _rememberBox.AutoSize = true;
            _rememberBox.Checked = true;

            _okButton.Text = "&Load";
            _okButton.AutoSize = true;
            _okButton.Click += (_, _) => AcceptSelection();

            _cancelButton.Text = "&Cancel";
            _cancelButton.AutoSize = true;
            _cancelButton.Click += (_, _) => { DialogResult = DialogResult.Cancel; Close(); };

            FlowLayoutPanel buttons = new()
            {
                Dock = DockStyle.Bottom,
                FlowDirection = FlowDirection.RightToLeft,
                AutoSize = true,
                Padding = new Padding(8)
            };
            buttons.Controls.Add(_cancelButton);
            buttons.Controls.Add(_okButton);

            FlowLayoutPanel options = new()
            {
                Dock = DockStyle.Bottom,
                FlowDirection = FlowDirection.LeftToRight,
                AutoSize = true,
                Padding = new Padding(12, 4, 8, 4)
            };
            options.Controls.Add(_rememberBox);

            Panel body = new() { Dock = DockStyle.Fill, Padding = new Padding(12, 0, 12, 0) };
            body.Controls.Add(_list);

            Controls.Add(body);
            Controls.Add(options);
            Controls.Add(buttons);
            Controls.Add(_header);

            AcceptButton = _okButton;
            CancelButton = _cancelButton;
        }

        private void AcceptSelection()
        {
            if (_list.SelectedItems.Count == 0) return;
            Chosen = _list.SelectedItems[0].Tag as ConnectionsFileResolver.Candidate;
            DialogResult = DialogResult.OK;
            Close();
        }

        private static string FormatSize(long bytes)
        {
            if (bytes < 1024) return $"{bytes} B";
            if (bytes < 1024 * 1024) return $"{bytes / 1024.0:F1} KB";
            return $"{bytes / (1024.0 * 1024):F1} MB";
        }

        private void ApplyTheme()
        {
            if (!ThemeManager.getInstance().ActiveAndExtended) return;
            if (ThemeManager.getInstance().ActiveTheme.ExtendedPalette is not { } palette) return;
            BackColor = palette.getColor("Dialog_Background");
            ForeColor = palette.getColor("Dialog_Foreground");
            _list.BackColor = palette.getColor("TextBox_Background");
            _list.ForeColor = palette.getColor("TextBox_Foreground");
        }

        /// <summary>
        /// Convenience factory matching <see cref="ConnectionsFileResolver.Resolve"/>'s delegate signature.
        /// </summary>
        public static (ConnectionsFileResolver.Candidate? Choice, bool RememberChoice) Prompt(
            IReadOnlyList<ConnectionsFileResolver.Candidate> candidates,
            ConnectionsFileResolver.Candidate? suggested)
        {
            using FrmChooseConnectionsFile dlg = new(candidates, suggested);
            DialogResult result = dlg.ShowDialog();
            return result == DialogResult.OK
                ? (dlg.Chosen, dlg.RememberChoice)
                : (null, false);
        }
    }
}
