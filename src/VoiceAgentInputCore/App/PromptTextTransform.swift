import Foundation

public protocol PromptTextTransform {
    func transform(_ text: String) async throws -> String
}

public struct AnyPromptTextTransform: PromptTextTransform {
    private var transformClosure: @Sendable (String) async throws -> String

    public init(_ transform: @escaping @Sendable (String) async throws -> String) {
        self.transformClosure = transform
    }

    public func transform(_ text: String) async throws -> String {
        try await transformClosure(text)
    }
}

public struct PromptTextTransformPipeline: PromptTextTransform {
    public var transforms: [any PromptTextTransform]

    public init(transforms: [any PromptTextTransform]) {
        self.transforms = transforms
    }

    public func transform(_ text: String) async throws -> String {
        var current = text
        for transform in transforms {
            current = try await transform.transform(current)
        }
        return current
    }
}

public struct DictionaryPromptTextTransform: PromptTextTransform {
    public var normalizer: any PromptNormalizer
    public var context: NormalizationContext

    public init(
        normalizer: any PromptNormalizer = DictionaryPromptNormalizer(),
        context: NormalizationContext
    ) {
        self.normalizer = normalizer
        self.context = context
    }

    public func transform(_ text: String) async throws -> String {
        try normalizer.normalizeText(text, context: context)
    }
}

public struct RefinementPromptTextTransform: PromptTextTransform {
    public var refiner: any PromptRefiner
    public var instruction: RefinementInstruction

    public init(
        refiner: any PromptRefiner = NoOpPromptRefiner(),
        instruction: RefinementInstruction = RefinementInstruction()
    ) {
        self.refiner = refiner
        self.instruction = instruction
    }

    public func transform(_ text: String) async throws -> String {
        try await refiner.refineText(text, instruction: instruction)
    }
}
