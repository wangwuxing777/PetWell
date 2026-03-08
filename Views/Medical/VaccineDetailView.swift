import SwiftUI

struct VaccineDetailView: View {
    let vaccine: Vaccine
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.96, green: 0.98, blue: 0.97),
                    Color(red: 1.00, green: 0.98, blue: 0.95),
                    Color.white
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            Circle()
                .fill(Color(red: 0.82, green: 0.90, blue: 0.86).opacity(0.30))
                .frame(width: 280, height: 280)
                .offset(x: 150, y: -310)

            Circle()
                .fill(Color(red: 0.78, green: 0.86, blue: 0.93).opacity(0.20))
                .frame(width: 220, height: 220)
                .offset(x: -170, y: 230)

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 22) {
                    heroCard
                    summaryCard
                    overviewCard
                    scheduleCard
                    bookingCard
                }
                .padding(.horizontal, 20)
                .padding(.top, 18)
                .padding(.bottom, 32)
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .toolbar(.hidden, for: .tabBar)
        .overlay(alignment: .topLeading) {
            Button {
                dismiss()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(Color(red: 0.17, green: 0.23, blue: 0.24))
                    .frame(width: 42, height: 42)
                    .background(Color.white.opacity(0.92), in: Circle())
                    .shadow(color: Color.black.opacity(0.06), radius: 10, y: 5)
            }
            .padding(.top, 12)
            .padding(.leading, 18)
        }
    }

    private var youngStageTitle: String {
        let type = vaccine.petType.lowercased()
        if type.contains("dog") && type.contains("cat") {
            return "Puppy / Kitten Stage"
        } else if type.contains("cat") {
            return "Kitten Stage"
        } else {
            return "Puppy Stage"
        }
    }

    private var statusTitle: String {
        if vaccine.isMandatory {
            return "Legally important protection"
        }

        return vaccine.isCore ? "Core immunity coverage" : "Lifestyle-based preventive care"
    }

    private var statusDescription: String {
        if vaccine.isMandatory {
            return "This vaccine is commonly required or strongly emphasized by regulation in many regions."
        }

        if vaccine.isCore {
            return "Recommended as foundational protection for long-term pet wellness and disease prevention."
        }

        return "Best used based on environment, travel patterns, social exposure, and day-to-day lifestyle risk."
    }

    private var coreLabel: String {
        vaccine.isCore ? "Core" : "Non-Core"
    }

    private var mandatoryLabel: String {
        vaccine.isMandatory ? "Mandatory" : "Optional"
    }

    private var heroCard: some View {
        VStack(alignment: .leading, spacing: 18) {
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(vaccine.petType.uppercased())
                            .font(.caption2.weight(.semibold))
                            .tracking(1)
                            .foregroundStyle(Color(red: 0.34, green: 0.45, blue: 0.46))

                        Text(vaccine.name)
                            .font(.system(size: 34, weight: .bold, design: .serif))
                            .foregroundStyle(Color(red: 0.12, green: 0.17, blue: 0.19))
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    Spacer(minLength: 16)

                    VStack(alignment: .trailing, spacing: 4) {
                        Text("Estimated")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        Text("$\(vaccine.price)")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundStyle(Color(red: 0.17, green: 0.35, blue: 0.41))
                    }
                }

                Text(statusTitle)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color(red: 0.25, green: 0.35, blue: 0.36))
            }

            VaccineDetailHeroImage(imageName: vaccine.imageName)

            HStack(spacing: 10) {
                DetailMetaPill(icon: "sparkles", title: coreLabel, tint: Color(red: 0.98, green: 0.93, blue: 0.80), foreground: Color(red: 0.62, green: 0.42, blue: 0.12))
                DetailMetaPill(icon: "checkmark.shield", title: mandatoryLabel, tint: vaccine.isMandatory ? Color(red: 1.00, green: 0.90, blue: 0.90) : Color(red: 0.93, green: 0.96, blue: 0.95), foreground: vaccine.isMandatory ? Color(red: 0.73, green: 0.22, blue: 0.22) : Color(red: 0.25, green: 0.36, blue: 0.36))
                DetailMetaPill(icon: "cross.case", title: "In-Clinic", tint: Color(red: 0.90, green: 0.95, blue: 0.93), foreground: Color(red: 0.16, green: 0.43, blue: 0.31))
            }
        }
        .padding(22)
        .background(Color.white.opacity(0.84), in: RoundedRectangle(cornerRadius: 30, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .stroke(Color.white.opacity(0.88), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.08), radius: 20, y: 12)
    }

    private var summaryCard: some View {
        VaccineDetailSectionCard(eyebrow: "AT A GLANCE", title: "Protection summary") {
            VStack(alignment: .leading, spacing: 14) {
                Text(statusDescription)
                    .font(.subheadline)
                    .foregroundStyle(Color(red: 0.35, green: 0.42, blue: 0.44))
                    .fixedSize(horizontal: false, vertical: true)

                HStack(spacing: 12) {
                    DetailStatBlock(value: vaccine.isCore ? "Core" : "Optional", label: "priority")
                    DetailStatBlock(value: vaccine.isMandatory ? "Required" : "Advised", label: "policy")
                    DetailStatBlock(value: "$\(vaccine.price)", label: "estimate")
                }
            }
        }
    }

    private var overviewCard: some View {
        VaccineDetailSectionCard(eyebrow: "OVERVIEW", title: "What this vaccine covers") {
            Text(vaccine.description)
                .font(.subheadline)
                .foregroundStyle(Color(red: 0.35, green: 0.42, blue: 0.44))
                .lineSpacing(5)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var scheduleCard: some View {
        VaccineDetailSectionCard(eyebrow: "SCHEDULE", title: "Recommended timing") {
            VStack(spacing: 16) {
                VaccineTimelineRow(
                    icon: "calendar.badge.clock",
                    title: youngStageTitle,
                    description: vaccine.youngInfo,
                    accent: Color(red: 0.18, green: 0.44, blue: 0.60)
                )

                Divider()

                VaccineTimelineRow(
                    icon: "arrow.clockwise.circle",
                    title: "Adult Stage",
                    description: vaccine.adultInfo,
                    accent: Color(red: 0.33, green: 0.47, blue: 0.41)
                )
            }
        }
    }

    private var bookingCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Next Step")
                .font(.caption2.weight(.semibold))
                .tracking(1)
                .foregroundStyle(Color.white.opacity(0.78))

            Text("Book a clinic appointment when you're ready")
                .font(.title3.weight(.bold))
                .foregroundStyle(.white)

            Text("Compare clinics, check availability, and move straight into booking from the app.")
                .font(.subheadline)
                .foregroundStyle(Color.white.opacity(0.82))
                .fixedSize(horizontal: false, vertical: true)

            NavigationLink(destination: ClinicSelectionView(vaccine: vaccine)) {
                HStack(spacing: 8) {
                    Text("Book Appointment")
                    Image(systemName: "arrow.right")
                }
                .font(.headline.weight(.semibold))
                .foregroundStyle(Color(red: 0.15, green: 0.22, blue: 0.24))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Color.white, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            }
            .buttonStyle(.plain)
        }
        .padding(22)
        .background(
            LinearGradient(
                colors: [
                    Color(red: 0.16, green: 0.26, blue: 0.29),
                    Color(red: 0.22, green: 0.40, blue: 0.41),
                    Color(red: 0.49, green: 0.63, blue: 0.57)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            in: RoundedRectangle(cornerRadius: 28, style: .continuous)
        )
        .shadow(color: Color.black.opacity(0.10), radius: 18, y: 12)
    }
}

private struct VaccineDetailHeroImage: View {
    let imageName: String

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [Color(red: 0.98, green: 0.98, blue: 0.96), Color.white],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )

            if let uiImage = UIImage(named: imageName) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFit()
                    .padding(14)
            } else {
                Image(systemName: "pawprint.fill")
                    .font(.system(size: 42))
                    .foregroundStyle(Color(red: 0.75, green: 0.80, blue: 0.78))
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 280)
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(Color(red: 0.95, green: 0.95, blue: 0.93), lineWidth: 1)
        )
    }
}

private struct DetailMetaPill: View {
    let icon: String
    let title: String
    let tint: Color
    let foreground: Color

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.caption.weight(.semibold))
            Text(title)
                .font(.caption.weight(.semibold))
        }
        .foregroundStyle(foreground)
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity)
        .background(tint, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

private struct DetailStatBlock: View {
    let value: String
    let label: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(value)
                .font(.headline.weight(.bold))
                .foregroundStyle(Color(red: 0.16, green: 0.23, blue: 0.24))

            Text(label.uppercased())
                .font(.caption2.weight(.semibold))
                .tracking(0.8)
                .foregroundStyle(Color(red: 0.41, green: 0.49, blue: 0.50))
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(red: 0.95, green: 0.97, blue: 0.96), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
}

private struct VaccineDetailSectionCard<Content: View>: View {
    let eyebrow: String
    let title: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 5) {
                Text(eyebrow)
                    .font(.caption2.weight(.semibold))
                    .tracking(1)
                    .foregroundStyle(Color(red: 0.34, green: 0.46, blue: 0.47))

                Text(title)
                    .font(.title3.weight(.bold))
                    .foregroundStyle(Color(red: 0.13, green: 0.18, blue: 0.20))
            }

            content
        }
        .padding(22)
        .background(Color.white.opacity(0.84), in: RoundedRectangle(cornerRadius: 28, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .stroke(Color.white.opacity(0.92), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.06), radius: 16, y: 10)
    }
}

private struct VaccineTimelineRow: View {
    let icon: String
    let title: String
    let description: String
    let accent: Color

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            ZStack {
                Circle()
                    .fill(accent.opacity(0.14))
                    .frame(width: 42, height: 42)

                Image(systemName: icon)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(accent)
            }

            VStack(alignment: .leading, spacing: 5) {
                Text(title)
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(Color(red: 0.14, green: 0.18, blue: 0.21))

                Text(description)
                    .font(.subheadline)
                    .foregroundStyle(Color(red: 0.35, green: 0.42, blue: 0.44))
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

struct VaccineDetailView_Previews: PreviewProvider {
    static var previews: some View {
        VaccineDetailView(vaccine: Vaccine(
            id: 1,
            name: "Rabies",
            petType: "dog/cat",
            description: "A must-have vaccine that protects your pet from rabies — a deadly virus.",
            youngInfo: "First dose at 12–16 weeks old.",
            adultInfo: "Booster 1 year later.",
            isCore: true,
            isMandatory: true,
            price: 280
        ))
    }
}
