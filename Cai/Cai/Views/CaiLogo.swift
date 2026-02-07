import SwiftUI

/// The Cai logo rendered as a SwiftUI Shape from the SVG paths.
/// Scales to fit any frame while preserving aspect ratio.
/// Original viewBox: 242 x 129
struct CaiLogo: View {
    var color: Color = .caiTextSecondary

    var body: some View {
        CaiLogoShape()
            .fill(color)
            .aspectRatio(242.0 / 129.0, contentMode: .fit)
    }
}

/// Shape that draws the Cai logo paths, normalized to a unit coordinate system.
struct CaiLogoShape: Shape {
    func path(in rect: CGRect) -> Path {
        let scaleX = rect.width / 242.0
        let scaleY = rect.height / 129.0

        var path = Path()
        let transform = CGAffineTransform(scaleX: scaleX, y: scaleY)
            .translatedBy(x: rect.minX / scaleX, y: rect.minY / scaleY)

        // "C" letter path
        path.addPath(cPath().applying(transform))

        // "ai" ligature path
        path.addPath(aiPath().applying(transform))

        return path
    }

    /// The "C" letterform
    private func cPath() -> Path {
        var p = Path()
        p.move(to: CGPoint(x: 213.864, y: 85.2244))
        p.addLine(to: CGPoint(x: 241.827, y: 85.2244))
        p.addCurve(to: CGPoint(x: 234.75, y: 108.06),
                    control1: CGPoint(x: 241.367, y: 93.8417),
                    control2: CGPoint(x: 239.008, y: 101.454))
        p.addCurve(to: CGPoint(x: 217.23, y: 123.485),
                    control1: CGPoint(x: 230.55, y: 114.609),
                    control2: CGPoint(x: 224.71, y: 119.751))
        p.addCurve(to: CGPoint(x: 190.561, y: 129),
                    control1: CGPoint(x: 209.75, y: 127.162),
                    control2: CGPoint(x: 200.86, y: 129))
        p.addCurve(to: CGPoint(x: 168.466, y: 124.778),
                    control1: CGPoint(x: 182.333, y: 129),
                    control2: CGPoint(x: 174.968, y: 127.593))
        p.addCurve(to: CGPoint(x: 151.895, y: 112.713),
                    control1: CGPoint(x: 161.965, y: 121.963),
                    control2: CGPoint(x: 156.441, y: 117.941))
        p.addCurve(to: CGPoint(x: 141.539, y: 93.6693),
                    control1: CGPoint(x: 147.407, y: 107.428),
                    control2: CGPoint(x: 143.955, y: 101.08))
        p.addCurve(to: CGPoint(x: 138, y: 68.4208),
                    control1: CGPoint(x: 139.18, y: 86.2011),
                    control2: CGPoint(x: 138, y: 77.7849))
        p.addLine(to: CGPoint(x: 138, y: 60.7515))
        p.addCurve(to: CGPoint(x: 141.711, y: 35.503),
                    control1: CGPoint(x: 138, y: 51.3874),
                    control2: CGPoint(x: 139.237, y: 42.9713))
        p.addCurve(to: CGPoint(x: 152.327, y: 16.3727),
                    control1: CGPoint(x: 144.185, y: 28.0347),
                    control2: CGPoint(x: 147.724, y: 21.658))
        p.addCurve(to: CGPoint(x: 168.898, y: 4.22245),
                    control1: CGPoint(x: 156.93, y: 11.0875),
                    control2: CGPoint(x: 162.454, y: 7.03741))
        p.addCurve(to: CGPoint(x: 190.475, y: 0),
                    control1: CGPoint(x: 175.342, y: 1.40748),
                    control2: CGPoint(x: 182.534, y: 0))
        p.addCurve(to: CGPoint(x: 217.575, y: 5.77355),
                    control1: CGPoint(x: 201.177, y: 0),
                    control2: CGPoint(x: 210.21, y: 1.92452))
        p.addCurve(to: CGPoint(x: 234.664, y: 21.6293),
                    control1: CGPoint(x: 224.94, y: 9.62258),
                    control2: CGPoint(x: 230.636, y: 14.9078))
        p.addCurve(to: CGPoint(x: 242, y: 44.6373),
                    control1: CGPoint(x: 238.749, y: 28.3507),
                    control2: CGPoint(x: 241.194, y: 36.02))
        p.addLine(to: CGPoint(x: 213.95, y: 44.6373))
        p.addCurve(to: CGPoint(x: 211.188, y: 32.3146),
                    control1: CGPoint(x: 213.72, y: 39.7542),
                    control2: CGPoint(x: 212.799, y: 35.6466))
        p.addCurve(to: CGPoint(x: 203.766, y: 24.6453),
                    control1: CGPoint(x: 209.577, y: 28.9252),
                    control2: CGPoint(x: 207.103, y: 26.3687))
        p.addCurve(to: CGPoint(x: 190.475, y: 22.0601),
                    control1: CGPoint(x: 200.429, y: 22.9218),
                    control2: CGPoint(x: 195.998, y: 22.0601))
        p.addCurve(to: CGPoint(x: 179.859, y: 24.3006),
                    control1: CGPoint(x: 186.447, y: 22.0601),
                    control2: CGPoint(x: 182.908, y: 22.8069))
        p.addCurve(to: CGPoint(x: 172.35, y: 31.2806),
                    control1: CGPoint(x: 176.867, y: 25.7943),
                    control2: CGPoint(x: 174.364, y: 28.1209))
        p.addCurve(to: CGPoint(x: 167.949, y: 43.3447),
                    control1: CGPoint(x: 170.394, y: 34.4402),
                    control2: CGPoint(x: 168.927, y: 38.4616))
        p.addCurve(to: CGPoint(x: 166.481, y: 60.5792),
                    control1: CGPoint(x: 166.97, y: 48.1703),
                    control2: CGPoint(x: 166.481, y: 53.9152))
        p.addLine(to: CGPoint(x: 166.481, y: 68.4208))
        p.addCurve(to: CGPoint(x: 167.776, y: 85.5691),
                    control1: CGPoint(x: 166.481, y: 75.0274),
                    control2: CGPoint(x: 166.913, y: 80.7435))
        p.addCurve(to: CGPoint(x: 171.919, y: 97.5471),
                    control1: CGPoint(x: 168.639, y: 90.3948),
                    control2: CGPoint(x: 170.02, y: 94.3874))
        p.addCurve(to: CGPoint(x: 179.427, y: 104.613),
                    control1: CGPoint(x: 173.875, y: 100.707),
                    control2: CGPoint(x: 176.378, y: 103.062))
        p.addCurve(to: CGPoint(x: 190.561, y: 106.94),
                    control1: CGPoint(x: 182.477, y: 106.164),
                    control2: CGPoint(x: 186.188, y: 106.94))
        p.addCurve(to: CGPoint(x: 203.076, y: 104.613),
                    control1: CGPoint(x: 195.567, y: 106.94),
                    control2: CGPoint(x: 199.738, y: 106.164))
        p.addCurve(to: CGPoint(x: 210.757, y: 97.3747),
                    control1: CGPoint(x: 206.413, y: 103.005),
                    control2: CGPoint(x: 208.973, y: 100.592))
        p.addCurve(to: CGPoint(x: 213.864, y: 85.2244),
                    control1: CGPoint(x: 212.541, y: 94.1576),
                    control2: CGPoint(x: 213.576, y: 90.1075))
        p.closeSubpath()
        return p
    }

    /// The "ai" ligature (slash + dot)
    private func aiPath() -> Path {
        var p = Path()

        // Main diagonal + bottom bar
        p.move(to: CGPoint(x: 85.7188, y: 110))
        p.addLine(to: CGPoint(x: 34.9873, y: 39.7917))
        p.addLine(to: CGPoint(x: 0, y: 39.7917))
        p.addLine(to: CGPoint(x: 0, y: 25))
        p.addLine(to: CGPoint(x: 39.2812, y: 25))
        p.addLine(to: CGPoint(x: 90.0127, y: 95.2083))
        p.addLine(to: CGPoint(x: 125, y: 95.2083))
        p.addLine(to: CGPoint(x: 125, y: 110))
        p.closeSubpath()

        // Top-right dot/bar
        p.move(to: CGPoint(x: 85.7188, y: 39.7917))
        p.addLine(to: CGPoint(x: 85.7188, y: 25))
        p.addLine(to: CGPoint(x: 125, y: 25))
        p.addLine(to: CGPoint(x: 125, y: 39.7917))
        p.closeSubpath()

        return p
    }
}
