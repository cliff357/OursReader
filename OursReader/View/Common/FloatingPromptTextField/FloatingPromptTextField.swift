//
//  Created by Emilio Peláez on 14/6/21.
//

import SwiftUI

/// A text input control with a prompt that moves or "floats" when it
/// becomes focused, and for as long as the input text is not empty.
public struct FloatingPromptTextField<Prompt: View, FloatingPrompt: View, TextFieldStyle: ShapeStyle>: View {
	
	enum PromptState {
		case normal
		case floating
	}
	
	@FocusState private var isFocused: Bool
	
	private var text: Binding<String>
	private let textFieldStyle: TextFieldStyle
    private let isSecure: Bool?
	private let prompt: Prompt
	private let floatingPrompt: FloatingPrompt
	
	@Environment(\.floatingPromptScale) var floatingPromptScale
	@Environment(\.floatingPromptSpacing) var floatingPromptSpacing
	@Environment(\.promptLeadingMargin) var promptLeadingMargin
	@Environment(\.animateFloatingPromptHeight) var animateFloatingPromptHeight
	
	@State private var promptState: PromptState
	@State private var promptHeight: Double = 0
    @State private var isPasswordVisible: Bool = false
	
	private var floatingOffset: Double { floatingPromptSpacing + promptHeight * floatingPromptScale }
	private var topMargin: Double { animateFloatingPromptHeight && promptState == .normal ? 0 : floatingOffset }
	
	fileprivate init(text: Binding<String>,
	                 textFieldStyle: TextFieldStyle,
                     isSecure: Bool? = false,
	                 @ViewBuilder prompt: () -> Prompt,
	                 @ViewBuilder floatingPrompt: () -> FloatingPrompt) {
		self.text = text
		self.prompt = prompt()
        self.isSecure = isSecure
		self.floatingPrompt = floatingPrompt()
		
		self.textFieldStyle = textFieldStyle
		
		_promptState = State(initialValue: text.wrappedValue.isEmpty ? .normal : .floating)
	}
	
	public var body: some View {
		ZStack(alignment: .leading) {
            Group{
                if isSecure ?? false && !isPasswordVisible {
                    SecureField("", text: text)
                } else {
                    TextField("", text: text)
                }
            }
            .if(isSecure ?? false) { view in
                view.overlay(alignment: .trailing) {
                    Image(systemName: isPasswordVisible ? "eye.fill" : "eye.slash.fill")
                        .padding()
                        .onTapGesture {
                            isPasswordVisible.toggle()
                        }
                }
            }
            .foregroundStyle(textFieldStyle)
            .focused($isFocused)
			ZStack(alignment: .leading) {
				prompt
					.opacity(promptState == .normal ? 1 : 0)
				floatingPrompt
					.background(
						GeometryReader { proxy in
							Color.clear
								.preference(key: HeightPreferenceKey.self, value: proxy.size.height)
						}
					)
					.opacity(promptState == .floating ? 1 : 0)
			}
			.padding(.leading, promptLeadingMargin)
			.scaleEffect(promptState == .floating ? floatingPromptScale : 1, anchor: .topLeading)
			.offset(x: 0, y: promptState == .floating ? -floatingOffset : 0)
		}
		.padding(.top, topMargin)
		.onChange(of: text.wrappedValue) { _ in updateState() }
		.onChange(of: isFocused) { _ in updateState() }
		.onPreferenceChange(HeightPreferenceKey.self) { height in
			promptHeight = height
		}
		.onTapGesture { isFocused = true }
		.accessibilityRepresentation {
			TextField(text: text, prompt: nil) {
				switch promptState {
				case .normal:
					prompt
				case .floating:
					floatingPrompt
				}
			}
		}
	}
	
	func updateState() {
		withAnimation {
			promptState = (!text.wrappedValue.isEmpty || isFocused) ? .floating : .normal
		}
	}
}

private extension FloatingPromptTextField where TextFieldStyle == HierarchicalShapeStyle {
	init(text: Binding<String>,
         isSecure: Bool,
	     @ViewBuilder prompt: () -> Prompt,
	     @ViewBuilder floatingPrompt: () -> FloatingPrompt) {
		self.init(text: text,
                  textFieldStyle: .primary, 
                  isSecure: isSecure,
		          prompt: prompt,
		          floatingPrompt: floatingPrompt)
	}
}

private extension FloatingPromptTextField where Prompt == FloatingPrompt {
	init(text: Binding<String>,
         isSecure: Bool,
	     textFieldStyle: TextFieldStyle,
	     @ViewBuilder prompt: () -> Prompt) {
		self.init(text: text,
                  textFieldStyle: textFieldStyle,
                  isSecure: isSecure,
		          prompt: prompt,
		          floatingPrompt: prompt)
	}
}

public extension FloatingPromptTextField where TextFieldStyle == HierarchicalShapeStyle, Prompt == FloatingPrompt {
	/// Creates a FloatingPromptTextField with a string binding and a view that will be used
	/// as the prompt.
	///
	/// - Parameters:
	///   - text: A binding to the text to display and edit.
	///   - prompt: A view that will be used as a prompt when the text field
	///   is empty, and as a floating prompt when it's focused or not empty,
	init(text: Binding<String>,
         isSecure: Bool,
	     @ViewBuilder prompt: () -> Prompt) {
		self.init(text: text,
                  textFieldStyle: .primary, 
                  isSecure: isSecure,
		          prompt: prompt,
		          floatingPrompt: prompt)
	}
}

public extension FloatingPromptTextField where TextFieldStyle == HierarchicalShapeStyle, Prompt == Text, FloatingPrompt == Text {
	/// Creates a FloatingPromptTextField with a string binding and a Text view that will be
	/// used as the prompt.
	///
	/// - Parameters:
	///   - text: A binding to the text to display and edit.
	///   - prompt: A Text view that will be used as a prompt when the text field
	///   is empty, and as a floating prompt when it's focused or not empty.
	init(text: Binding<String>, 
         isSecure: Bool,
         prompt: Text) {
		self.init(text: text,
                  textFieldStyle: .primary, 
                  isSecure: isSecure,
		          prompt: { prompt.foregroundColor(.secondary) },
		          floatingPrompt: { prompt.foregroundColor(.accentColor) })
	}
}

public extension FloatingPromptTextField {
	/// A `View` to be used as the floating prompt when the text field is focused
	/// or not empty.
	///
	/// - Parameter floatingPrompt: The view that will be used as the floating
	/// prompt when the text field is focused or not empty.
	func floatingPrompt<FloatingPromptType: View>(_ floatingPrompt: () -> FloatingPromptType) -> FloatingPromptTextField<Prompt, FloatingPromptType, TextFieldStyle> {
		FloatingPromptTextField<Prompt, FloatingPromptType, TextFieldStyle>(
			text: text,
            textFieldStyle: textFieldStyle,
            isSecure: isSecure,
			prompt: { prompt },
			floatingPrompt: { floatingPrompt() }
		)
	}
	
	/// Sets the style for the text field. You can use this to set the color of the
	/// text in the text field.
	func textFieldForegroundStyle<Style: ShapeStyle>(_ style: Style) -> FloatingPromptTextField<Prompt, FloatingPrompt, Style> {
		FloatingPromptTextField<Prompt, FloatingPrompt, Style>(
			text: text,
            textFieldStyle: style,
            isSecure: isSecure,
			prompt: { prompt },
			floatingPrompt: { floatingPrompt }
		)
	}
}
