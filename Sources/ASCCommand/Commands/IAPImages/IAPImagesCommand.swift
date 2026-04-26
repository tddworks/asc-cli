import ArgumentParser

struct IAPImagesCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "iap-images",
        abstract: "Manage 1024x1024 promotional images for an in-app purchase",
        subcommands: [
            IAPImagesList.self,
            IAPImagesUpload.self,
            IAPImagesDelete.self,
        ]
    )
}
