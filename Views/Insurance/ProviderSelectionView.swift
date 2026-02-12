import SwiftUI

struct ProviderSelectionView: View {
  @Binding var isPresented: Bool
  let onSelect: (Int) -> Void
  @ObservedObject var service = InsuranceService.shared

  var body: some View {
    NavigationView {
      List(service.products) { product in
        Button(action: {
          onSelect(product.insuranceId)
          isPresented = false
        }) {
          HStack {
            VStack(alignment: .leading) {
              if let company = service.getCompany(forProduct: product) {
                Text(company.companyName)
                  .font(.headline)
              }
              Text(product.insuranceName)
                .font(.subheadline)
                .foregroundColor(.secondary)
            }
            Spacer()
          }
        }
      }
      .navigationTitle("Select Insurance")
      .navigationBarItems(trailing: Button("Cancel") { isPresented = false })
    }
  }
}
