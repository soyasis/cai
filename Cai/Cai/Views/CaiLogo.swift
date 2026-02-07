import SwiftUI

/// The Cai logo rendered as a SwiftUI Shape from the SVG paths.
/// Scales to fit any frame while preserving aspect ratio.
/// Original viewBox: 217 x 127
struct CaiLogo: View {
    var color: Color = .caiTextSecondary

    var body: some View {
        CaiLogoShape()
            .fill(color)
            .aspectRatio(217.0 / 127.0, contentMode: .fit)
    }
}

/// Shape that draws the Cai logo paths, normalized to a unit coordinate system.
struct CaiLogoShape: Shape {
    func path(in rect: CGRect) -> Path {
        let scaleX = rect.width / 217.0
        let scaleY = rect.height / 127.0

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
        p.move(to: CGPoint(x: 189.405, y: 83.9031))
        p.addLine(to: CGPoint(x: 216.831, y: 83.9031))
        p.addCurve(to: CGPoint(x: 209.89, y: 106.385),
                    control1: CGPoint(x: 216.379, y: 92.3868),
                    control2: CGPoint(x: 214.066, y: 99.8806))
        p.addCurve(to: CGPoint(x: 192.706, y: 121.57),
                    control1: CGPoint(x: 205.77, y: 112.832),
                    control2: CGPoint(x: 200.042, y: 117.894))
        p.addCurve(to: CGPoint(x: 166.55, y: 127),
                    control1: CGPoint(x: 185.37, y: 125.19),
                    control2: CGPoint(x: 176.651, y: 127))
        p.addCurve(to: CGPoint(x: 144.88, y: 122.843),
                    control1: CGPoint(x: 158.48, y: 127),
                    control2: CGPoint(x: 151.257, y: 125.614))
        p.addCurve(to: CGPoint(x: 128.628, y: 110.966),
                    control1: CGPoint(x: 138.504, y: 120.072),
                    control2: CGPoint(x: 133.086, y: 116.113))
        p.addCurve(to: CGPoint(x: 118.471, y: 92.2171),
                    control1: CGPoint(x: 124.227, y: 105.763),
                    control2: CGPoint(x: 120.841, y: 99.513))
        p.addCurve(to: CGPoint(x: 115, y: 67.3601),
                    control1: CGPoint(x: 116.157, y: 84.8646),
                    control2: CGPoint(x: 115, y: 76.5789))
        p.addLine(to: CGPoint(x: 115, y: 59.8096))
        p.addCurve(to: CGPoint(x: 118.64, y: 34.9526),
                    control1: CGPoint(x: 115, y: 50.5907),
                    control2: CGPoint(x: 116.213, y: 42.3051))
        p.addCurve(to: CGPoint(x: 129.051, y: 16.1189),
                    control1: CGPoint(x: 121.066, y: 27.6001),
                    control2: CGPoint(x: 124.537, y: 21.3222))
        p.addCurve(to: CGPoint(x: 145.304, y: 4.15698),
                    control1: CGPoint(x: 133.566, y: 10.9156),
                    control2: CGPoint(x: 138.983, y: 6.9283))
        p.addCurve(to: CGPoint(x: 166.466, y: 0),
                    control1: CGPoint(x: 151.624, y: 1.38566),
                    control2: CGPoint(x: 158.678, y: 0))
        p.addCurve(to: CGPoint(x: 193.045, y: 5.68403),
                    control1: CGPoint(x: 176.962, y: 0),
                    control2: CGPoint(x: 185.822, y: 1.89468))
        p.addCurve(to: CGPoint(x: 209.805, y: 21.2939),
                    control1: CGPoint(x: 200.268, y: 9.47339),
                    control2: CGPoint(x: 205.855, y: 14.6767))
        p.addCurve(to: CGPoint(x: 217, y: 43.9452),
                    control1: CGPoint(x: 213.812, y: 27.9112),
                    control2: CGPoint(x: 216.21, y: 35.4616))
        p.addLine(to: CGPoint(x: 189.49, y: 43.9452))
        p.addCurve(to: CGPoint(x: 186.781, y: 31.8136),
                    control1: CGPoint(x: 189.264, y: 39.1378),
                    control2: CGPoint(x: 188.361, y: 35.094))
        p.addCurve(to: CGPoint(x: 179.501, y: 24.2632),
                    control1: CGPoint(x: 185.201, y: 28.4767),
                    control2: CGPoint(x: 182.774, y: 25.9599))
        p.addCurve(to: CGPoint(x: 166.466, y: 21.7181),
                    control1: CGPoint(x: 176.228, y: 22.5665),
                    control2: CGPoint(x: 171.883, y: 21.7181))
        p.addCurve(to: CGPoint(x: 156.054, y: 23.9238),
                    control1: CGPoint(x: 162.515, y: 21.7181),
                    control2: CGPoint(x: 159.045, y: 22.4534))
        p.addCurve(to: CGPoint(x: 148.69, y: 30.7956),
                    control1: CGPoint(x: 153.119, y: 25.3943),
                    control2: CGPoint(x: 150.665, y: 27.6849))
        p.addCurve(to: CGPoint(x: 144.373, y: 42.6727),
                    control1: CGPoint(x: 146.771, y: 33.9063),
                    control2: CGPoint(x: 145.332, y: 37.8653))
        p.addCurve(to: CGPoint(x: 142.934, y: 59.6399),
                    control1: CGPoint(x: 143.413, y: 47.4235),
                    control2: CGPoint(x: 142.934, y: 53.0793))
        p.addLine(to: CGPoint(x: 142.934, y: 67.3601))
        p.addCurve(to: CGPoint(x: 144.203, y: 84.2425),
                    control1: CGPoint(x: 142.934, y: 73.8642),
                    control2: CGPoint(x: 143.357, y: 79.4916))
        p.addCurve(to: CGPoint(x: 148.266, y: 96.0347),
                    control1: CGPoint(x: 145.05, y: 88.9933),
                    control2: CGPoint(x: 146.404, y: 92.9241))
        p.addCurve(to: CGPoint(x: 155.631, y: 102.991),
                    control1: CGPoint(x: 150.185, y: 99.1454),
                    control2: CGPoint(x: 152.64, y: 101.464))
        p.addCurve(to: CGPoint(x: 166.55, y: 105.282),
                    control1: CGPoint(x: 158.622, y: 104.518),
                    control2: CGPoint(x: 162.261, y: 105.282))
        p.addCurve(to: CGPoint(x: 178.824, y: 102.991),
                    control1: CGPoint(x: 171.46, y: 105.282),
                    control2: CGPoint(x: 175.551, y: 104.518))
        p.addCurve(to: CGPoint(x: 186.358, y: 95.8651),
                    control1: CGPoint(x: 182.097, y: 101.408),
                    control2: CGPoint(x: 184.608, y: 99.0323))
        p.addCurve(to: CGPoint(x: 189.405, y: 83.9031),
                    control1: CGPoint(x: 188.107, y: 92.6978),
                    control2: CGPoint(x: 189.123, y: 88.7105))
        p.closeSubpath()
        return p
    }

    /// The "ai" ligature (slash + dot)
    private func aiPath() -> Path {
        var p = Path()

        // Main diagonal + bottom bar
        p.move(to: CGPoint(x: 32.7051, y: 29.5))
        p.addLine(to: CGPoint(x: 32.8506, y: 29.7383))
        p.addLine(to: CGPoint(x: 73.29, y: 95.5781))
        p.addLine(to: CGPoint(x: 101.5, y: 95.5781))
        p.addLine(to: CGPoint(x: 101.5, y: 110.5))
        p.addLine(to: CGPoint(x: 69.2949, y: 110.5))
        p.addLine(to: CGPoint(x: 69.1494, y: 110.262))
        p.addLine(to: CGPoint(x: 28.71, y: 44.4219))
        p.addLine(to: CGPoint(x: 0.5, y: 44.4219))
        p.addLine(to: CGPoint(x: 0.5, y: 29.5))
        p.closeSubpath()

        // Top-right dot/bar
        p.move(to: CGPoint(x: 101.5, y: 29.5))
        p.addLine(to: CGPoint(x: 101.5, y: 44.4219))
        p.addLine(to: CGPoint(x: 69.0752, y: 44.4219))
        p.addLine(to: CGPoint(x: 69.0752, y: 29.5))
        p.closeSubpath()

        return p
    }
}
