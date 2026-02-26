using System;
using System.Drawing;
using System.Windows.Forms;
using mRemoteNG.UI;

namespace mRemoteNG.UI.Forms
{
    public class FullscreenToolbar : Form
    {
        private Button _btnMinimize = null!;
        private Button _btnRestore = null!;
        private Button _btnClose = null!;
        private readonly Form _targetForm;
        private readonly FullscreenHandler _fullscreenHandler;

        // Drag-to-exit-fullscreen state
        private Point _dragStartScreen;
        private bool _dragActive;
        private const int DragDownThreshold = 30;

        public FullscreenToolbar(Form targetForm, FullscreenHandler fullscreenHandler)
        {
            _targetForm = targetForm;
            _fullscreenHandler = fullscreenHandler;
            InitializeComponent();
            HookDragToExit(this);
            HookDragToExit(_btnMinimize);
            HookDragToExit(_btnRestore);
            HookDragToExit(_btnClose);
        }

        private void InitializeComponent()
        {
            _btnMinimize = new Button();
            _btnRestore = new Button();
            _btnClose = new Button();

            SuspendLayout();

            //
            // FullscreenToolbar properties
            //
            FormBorderStyle = FormBorderStyle.None;
            TopMost = true;
            ShowInTaskbar = false;
            Size = new Size(120, 26);
            BackColor = Color.FromArgb(45, 45, 48); // Dark VS-like background
            Opacity = 0.9;
            Padding = new Padding(2);
            StartPosition = FormStartPosition.Manual;

            //
            // btnMinimize
            //
            _btnMinimize.FlatStyle = FlatStyle.Flat;
            _btnMinimize.FlatAppearance.BorderSize = 0;
            _btnMinimize.FlatAppearance.MouseOverBackColor = Color.FromArgb(62, 62, 64);
            _btnMinimize.ForeColor = Color.White;
            _btnMinimize.Location = new Point(2, 2);
            _btnMinimize.Name = "btnMinimize";
            _btnMinimize.Size = new Size(38, 22);
            _btnMinimize.Text = "0"; // Marlett Minimize
            _btnMinimize.Font = new Font("Marlett", 8.5F, FontStyle.Regular, GraphicsUnit.Point);
            _btnMinimize.UseVisualStyleBackColor = true;
            _btnMinimize.Click += (s, e) => _targetForm.WindowState = FormWindowState.Minimized;

            //
            // btnRestore
            //
            _btnRestore.FlatStyle = FlatStyle.Flat;
            _btnRestore.FlatAppearance.BorderSize = 0;
            _btnRestore.FlatAppearance.MouseOverBackColor = Color.FromArgb(62, 62, 64);
            _btnRestore.ForeColor = Color.White;
            _btnRestore.Location = new Point(42, 2);
            _btnRestore.Name = "btnRestore";
            _btnRestore.Size = new Size(38, 22);
            _btnRestore.Text = "2"; // Marlett Restore
            _btnRestore.Font = new Font("Marlett", 8.5F, FontStyle.Regular, GraphicsUnit.Point);
            _btnRestore.UseVisualStyleBackColor = true;
            _btnRestore.Click += (s, e) => _fullscreenHandler.Value = false; // Exit fullscreen

            //
            // btnClose
            //
            _btnClose.FlatStyle = FlatStyle.Flat;
            _btnClose.FlatAppearance.BorderSize = 0;
            _btnClose.FlatAppearance.MouseOverBackColor = Color.FromArgb(232, 17, 35); // Red for close
            _btnClose.ForeColor = Color.White;
            _btnClose.Location = new Point(82, 2);
            _btnClose.Name = "btnClose";
            _btnClose.Size = new Size(38, 22);
            _btnClose.Text = "r"; // Marlett Close
            _btnClose.Font = new Font("Marlett", 8.5F, FontStyle.Regular, GraphicsUnit.Point);
            _btnClose.UseVisualStyleBackColor = true;
            _btnClose.Click += (s, e) => _targetForm.Close();

            Controls.Add(_btnMinimize);
            Controls.Add(_btnRestore);
            Controls.Add(_btnClose);

            ResumeLayout(false);
        }

        protected override bool ShowWithoutActivation => true; // Prevent stealing focus

        // Attach drag detection to the toolbar form and all its buttons.
        // Dragging down more than DragDownThreshold pixels exits fullscreen mode,
        // mirroring the behavior of Microsoft's RDP client title bar (#2223).
        private void HookDragToExit(Control control)
        {
            control.MouseDown += OnDragMouseDown;
            control.MouseMove += OnDragMouseMove;
            control.MouseUp += OnDragMouseUp;
        }

        private void OnDragMouseDown(object? sender, MouseEventArgs e)
        {
            if (e.Button == MouseButtons.Left && sender is Control c)
            {
                _dragStartScreen = c.PointToScreen(e.Location);
                _dragActive = true;
            }
        }

        private void OnDragMouseMove(object? sender, MouseEventArgs e)
        {
            if (!_dragActive || e.Button != MouseButtons.Left || sender is not Control c)
                return;

            var pos = c.PointToScreen(e.Location);
            if (pos.Y - _dragStartScreen.Y > DragDownThreshold)
            {
                _dragActive = false;
                // Defer to let the current mouse event complete before closing the toolbar
                BeginInvoke(new Action(() => _fullscreenHandler.Value = false));
            }
        }

        private void OnDragMouseUp(object? sender, MouseEventArgs e)
        {
            _dragActive = false;
        }
    }
}
