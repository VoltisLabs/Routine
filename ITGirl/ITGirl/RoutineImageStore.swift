import Foundation
import UIKit

/// Persists routine cover / gallery JPEGs on disk (referenced by `Routine.imageAttachmentIds`).
final class RoutineImageStore {
    static let shared = RoutineImageStore()

    private let directory: URL

    private init() {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        directory = base.appendingPathComponent("ITGirlRoutineImages", isDirectory: true)
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    }

    private func fileURL(for id: UUID) -> URL {
        directory.appendingPathComponent("\(id.uuidString).jpg")
    }

    func saveJPEG(data: Data, id: UUID) throws {
        try data.write(to: fileURL(for: id), options: .atomic)
    }

    func saveUIImage(_ image: UIImage, id: UUID, maxDimension: CGFloat = 1600) throws {
        let scaled = Self.scaleDown(image, maxDimension: maxDimension)
        guard let data = scaled.jpegData(compressionQuality: 0.82) else {
            throw NSError(domain: "ITGirl", code: 1, userInfo: [NSLocalizedDescriptionKey: "Could not encode image"])
        }
        try saveJPEG(data: data, id: id)
    }

    func loadData(id: UUID) -> Data? {
        try? Data(contentsOf: fileURL(for: id))
    }

    func delete(ids: [UUID]) {
        for id in ids {
            try? FileManager.default.removeItem(at: fileURL(for: id))
        }
    }

    /// Copy files to new ids (e.g. when saving a duplicate to Saved).
    func duplicate(ids: [UUID]) -> [UUID] {
        var newIds: [UUID] = []
        for old in ids {
            let newId = UUID()
            let src = fileURL(for: old)
            let dst = fileURL(for: newId)
            if FileManager.default.fileExists(atPath: src.path) {
                try? FileManager.default.copyItem(at: src, to: dst)
                newIds.append(newId)
            }
        }
        return newIds
    }

    private static func scaleDown(_ image: UIImage, maxDimension: CGFloat) -> UIImage {
        let size = image.size
        let maxSide = max(size.width, size.height)
        guard maxSide > maxDimension else { return image }
        let scale = maxDimension / maxSide
        let newSize = CGSize(width: size.width * scale, height: size.height * scale)
        let renderer = UIGraphicsImageRenderer(size: newSize)
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: newSize))
        }
    }
}
