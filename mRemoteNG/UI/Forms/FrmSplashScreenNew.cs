using System;
using System.Drawing;
using System.Drawing.Drawing2D;
using System.Drawing.Text;
using System.Runtime.InteropServices;
using System.Runtime.Versioning;
using System.Windows.Forms;
using mRemoteNG.App.Info;

namespace mRemoteNG.UI.Forms
{
    [SupportedOSPlatform("windows")]
    public class FrmSplashScreenNew : Form
    {
        private static FrmSplashScreenNew? instance;
        private PrivateFontCollection? _fontCollection;

        public FrmSplashScreenNew()
        {
            SetStyle(ControlStyles.SupportsTransparentBackColor | ControlStyles.AllPaintingInWmPaint | ControlStyles.UserPaint | ControlStyles.DoubleBuffer, true);
            FormBorderStyle = FormBorderStyle.None;
            StartPosition = FormStartPosition.Manual;
            ShowInTaskbar = false;
            BackColor = Color.Magenta;
            TransparencyKey = Color.Magenta;
            Size = new Size(450, 120);
            CenterOnPrimaryScreen();
        }

        private void CenterOnPrimaryScreen()
        {
            Rectangle workArea = Screen.PrimaryScreen?.WorkingArea ?? new Rectangle(0, 0, 1920, 1080);
            Left = workArea.Left + (workArea.Width - Width) / 2;
            Top = workArea.Top + (workArea.Height - Height) / 2;
        }

        protected override void OnPaint(PaintEventArgs e)
        {
            base.OnPaint(e);
            Graphics g = e.Graphics;
            g.SmoothingMode = SmoothingMode.AntiAlias;
            g.TextRenderingHint = TextRenderingHint.ClearTypeGridFit;

            // Background with rounded corners
            using GraphicsPath path = CreateRoundedRect(new Rectangle(0, 0, Width - 1, Height - 1), 10);
            using SolidBrush bgBrush = new(Color.FromArgb(0x37, 0x3C, 0x42));
            using Pen borderPen = new(Color.FromArgb(0x21, 0x1E, 0x1B), 1);
            g.FillPath(bgBrush, path);
            g.DrawPath(borderPen, path);

            Font? brandFont = LoadBrandFont(40f);
            Font fallbackFont = new("Segoe UI", 30f, FontStyle.Bold);
            Font titleFont = brandFont ?? fallbackFont;

            // "m" in blue
            using SolidBrush blueBrush = new(Color.FromArgb(0x52, 0x89, 0xF9));
            g.DrawString("m", titleFont, blueBrush, 104, 2);

            // "RemoteNG" in white
            float mWidth = g.MeasureString("m", titleFont).Width - 8;
            using SolidBrush whiteBrush = new(Color.FromArgb(0xE8, 0xEB, 0xEE));
            g.DrawString("RemoteNG", titleFont, whiteBrush, 104 + mWidth, 2);

            // Version
            using Font versionFont = new("Segoe UI", 12f);
            string versionText = $"v. {GeneralAppInfo.ApplicationVersion} - 'Fructus temporum'";
            SizeF versionSize = g.MeasureString(versionText, versionFont);
            g.DrawString(versionText, versionFont, whiteBrush, (Width - versionSize.Width) / 2, 55);

            // Subtitle
            using Font subtitleFont = new("Segoe UI", 11f, FontStyle.Bold);
            string subtitle = "Multi-Remote Next Generation Connection Manager";
            SizeF subtitleSize = g.MeasureString(subtitle, subtitleFont);
            g.DrawString(subtitle, subtitleFont, whiteBrush, (Width - subtitleSize.Width) / 2, 85);

            if (brandFont != null) brandFont.Dispose();
            fallbackFont.Dispose();
        }

        private Font? LoadBrandFont(float size)
        {
            try
            {
                string fontPath = System.IO.Path.Combine(AppDomain.CurrentDomain.BaseDirectory, "UI", "Font", "HANDELGB.TTF");
                if (!System.IO.File.Exists(fontPath)) return null;
                _fontCollection ??= new PrivateFontCollection();
                if (_fontCollection.Families.Length == 0)
                    _fontCollection.AddFontFile(fontPath);
                return new Font(_fontCollection.Families[0], size, FontStyle.Bold, GraphicsUnit.Pixel);
            }
            catch
            {
                return null;
            }
        }

        private static GraphicsPath CreateRoundedRect(Rectangle rect, int radius)
        {
            GraphicsPath path = new();
            int d = radius * 2;
            path.AddArc(rect.X, rect.Y, d, d, 180, 90);
            path.AddArc(rect.Right - d, rect.Y, d, d, 270, 90);
            path.AddArc(rect.Right - d, rect.Bottom - d, d, d, 0, 90);
            path.AddArc(rect.X, rect.Bottom - d, d, d, 90, 90);
            path.CloseFigure();
            return path;
        }

        public static FrmSplashScreenNew GetInstance()
        {
            instance ??= new FrmSplashScreenNew();
            return instance;
        }

        public new void Show()
        {
            base.Show();
            Application.DoEvents();
        }

        public new void Close()
        {
            base.Close();
            instance = null;
        }

        protected override void Dispose(bool disposing)
        {
            if (disposing)
            {
                _fontCollection?.Dispose();
                _fontCollection = null;
            }
            base.Dispose(disposing);
        }

        protected override CreateParams CreateParams
        {
            get
            {
                // WS_EX_LAYERED | WS_EX_TOOLWINDOW — allows per-pixel transparency, hidden from taskbar
                CreateParams cp = base.CreateParams;
                cp.ExStyle |= 0x00080000 | 0x00000080;
                return cp;
            }
        }
    }
}
