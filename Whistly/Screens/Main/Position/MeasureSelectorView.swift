import SwiftUI

struct MeasureSelectorView: View {
    @Environment(MainContainer.self) private var viewModel
    
    private var loops: [MeasureLoop] {
        viewModel.storage.loadedTune?.measureLoops ?? []
    }
    
    private var selectedLoopId: UUID? {
        viewModel.storage.loadedTune?.selectedLoopId
    }
    
    private var totalMeasures: Int {
        viewModel.sequencer.totalMeasures
    }
    
    @State private var showingAddLoop = false
    @State private var showingStartMeasureAlert = false
    @State private var showingEndMeasureAlert = false
    @State private var startMeasureInput = ""
    @State private var endMeasureInput = ""
    
    var body: some View {
        VStack(spacing: 12) {
            Text("Measures")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.white.opacity(0.8))
            
            HStack(spacing: 20) {
                VStack(spacing: 4) {
                    Text("From")
                        .font(.caption)
                        .foregroundColor(.gray)
                    
                    HStack(spacing: 8) {
                        Button(action: {
                            if viewModel.sequencer.startMeasure > 1 {
                                viewModel.sequencer.startMeasure -= 1
                            }
                        }) {
                            Image(systemName: "minus.circle.fill")
                                .font(.system(size: 28))
                                .foregroundColor(.purple.opacity(0.8))
                        }
                        
                        Button(action: {
                            startMeasureInput = "\(viewModel.sequencer.startMeasure)"
                            showingStartMeasureAlert = true
                        }) {
                        Text("\(viewModel.sequencer.startMeasure)")
                            .font(.system(size: 18, weight: .bold, design: .monospaced))
                            .foregroundColor(.white)
                            .frame(width: 40)
                        }
                        .buttonStyle(.plain)
                        
                        Button(action: {
                            if viewModel.sequencer.startMeasure < viewModel.sequencer.endMeasure {
                                viewModel.sequencer.startMeasure += 1
                            }
                        }) {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 28))
                                .foregroundColor(.purple.opacity(0.8))
                        }
                    }
                }
                
                Text("—")
                    .foregroundColor(.gray)
                
                VStack(spacing: 4) {
                    Text("To")
                        .font(.caption)
                        .foregroundColor(.gray)
                    
                    HStack(spacing: 8) {
                        Button(action: {
                            if viewModel.sequencer.endMeasure > viewModel.sequencer.startMeasure {
                                viewModel.sequencer.endMeasure -= 1
                            }
                        }) {
                            Image(systemName: "minus.circle.fill")
                                .font(.system(size: 28))
                                .foregroundColor(.cyan.opacity(0.8))
                        }
                        
                        Button(action: {
                            endMeasureInput = "\(viewModel.sequencer.endMeasure)"
                            showingEndMeasureAlert = true
                        }) {
                        Text("\(viewModel.sequencer.endMeasure)")
                            .font(.system(size: 18, weight: .bold, design: .monospaced))
                            .foregroundColor(.white)
                            .frame(width: 40)
                        }
                        .buttonStyle(.plain)
                        
                        Button(action: {
                            if viewModel.sequencer.endMeasure < viewModel.sequencer.totalMeasures {
                                viewModel.sequencer.endMeasure += 1
                            }
                        }) {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 28))
                                .foregroundColor(.cyan.opacity(0.8))
                        }
                    }
                }
            }
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    if loops.isEmpty {
                        QuickSelectButton(title: "All") {
                            viewModel.sequencer.startMeasure = 1
                            viewModel.sequencer.endMeasure = viewModel.sequencer.totalMeasures
                        }
                    } else {
                        ForEach(loops) { loop in
                            LoopButton(
                                loop: loop,
                                isSelected: selectedLoopId == loop.id,
                                totalMeasures: totalMeasures,
                                onSelect: {
                                    selectLoop(loop)
                                },
                                onRemove: loop.isDefault ? nil : {
                                    removeLoop(loopId: loop.id)
                                }
                            )
                        }
                    }
                    
                        Button(action: { showingAddLoop = true }) {
                            Image(systemName: "plus")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.green.opacity(0.8))
                                .frame(width: 32, height: 28)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color.green.opacity(0.3), style: StrokeStyle(lineWidth: 1, dash: [4]))
                                )
                    }
                }
                .padding(.horizontal, 4)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.05))
        )
        .alert("Add Loop", isPresented: $showingAddLoop) {
            Button("Cancel", role: .cancel) { }
            Button("Add") {
                addLoop(start: viewModel.sequencer.startMeasure, end: viewModel.sequencer.endMeasure)
            }
        } message: {
            Text("Add current range (\(viewModel.sequencer.startMeasure)-\(viewModel.sequencer.endMeasure)) as a new loop?")
        }
        .alert("Start Measure", isPresented: $showingStartMeasureAlert) {
            TextField("Measure", text: $startMeasureInput)
                .keyboardType(.numberPad)
            Button("Cancel", role: .cancel) { }
            Button("OK") {
                if let value = Int(startMeasureInput),
                   value >= 1,
                   value <= viewModel.sequencer.totalMeasures,
                   value <= viewModel.sequencer.endMeasure {
                    viewModel.sequencer.startMeasure = value
                }
            }
        } message: {
            Text("Enter start measure (1-\(viewModel.sequencer.totalMeasures))")
        }
        .alert("End Measure", isPresented: $showingEndMeasureAlert) {
            TextField("Measure", text: $endMeasureInput)
                .keyboardType(.numberPad)
            Button("Cancel", role: .cancel) { }
            Button("OK") {
                if let value = Int(endMeasureInput),
                   value >= 1,
                   value <= viewModel.sequencer.totalMeasures,
                   value >= viewModel.sequencer.startMeasure {
                    viewModel.sequencer.endMeasure = value
                }
            }
        } message: {
            Text("Enter end measure (\(viewModel.sequencer.startMeasure)-\(viewModel.sequencer.totalMeasures))")
        }
    }
    
    private func selectLoop(_ loop: MeasureLoop) {
        viewModel.sequencer.startMeasure = loop.startMeasure
        viewModel.sequencer.endMeasure = min(loop.endMeasure, viewModel.sequencer.totalMeasures)
       
        viewModel.storage.updateLoadedTune { tune in
            tune.selectedLoopId = loop.id
       }
    }
    
    private func addLoop(start: Int, end: Int) {
        guard viewModel.storage.loadedTune != nil else { return }
        
        let newLoop = MeasureLoop(
            startMeasure: start,
            endMeasure: end,
            isDefault: false,
            loopType: .segment
        )
        
        viewModel.storage.updateLoadedTune { tune in
            tune.measureLoops.append(newLoop)
            tune.selectedLoopId = newLoop.id
        }
        
        viewModel.sequencer.startMeasure = newLoop.startMeasure
        viewModel.sequencer.endMeasure = min(newLoop.endMeasure, viewModel.sequencer.totalMeasures)
    }
    
    private func removeLoop(loopId: UUID) {
        guard viewModel.storage.loadedTune != nil else { return }
        
        viewModel.storage.updateLoadedTune { tune in
            tune.measureLoops.removeAll { $0.id == loopId }
            
            if tune.selectedLoopId == loopId {
                tune.selectedLoopId = tune.measureLoops.first?.id
                if let firstLoop = tune.measureLoops.first {
                    viewModel.sequencer.startMeasure = firstLoop.startMeasure
                    viewModel.sequencer.endMeasure = min(firstLoop.endMeasure, viewModel.sequencer.totalMeasures)
                }
           }
       }
    }
}

struct QuickSelectButton: View {
    let title: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.white.opacity(0.7))
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(Color.white.opacity(0.1))
                )
        }
    }
}
struct LoopButton: View {
    let loop: MeasureLoop
    let isSelected: Bool
    let totalMeasures: Int
    var onSelect: () -> Void
    var onRemove: (() -> Void)?
    
    private var backgroundColor: LinearGradient {
        if isSelected {
            return LinearGradient.primary
        }
        
        switch loop.loopType {
        case .segment:
            return LinearGradient(
                colors: [Color.white.opacity(0.1)],
                startPoint: .leading,
                endPoint: .trailing
            )
        case .half:
            return LinearGradient(
                colors: [Color.blue.opacity(0.2), Color.cyan.opacity(0.15)],
                startPoint: .leading,
                endPoint: .trailing
            )
        case .full:
            return LinearGradient(
                colors: [Color.purple.opacity(0.2), Color.pink.opacity(0.15)],
                startPoint: .leading,
                endPoint: .trailing
            )
        }
    }
    
    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 4) {
                Text(loop.startMeasure == 1 && loop.endMeasure >= totalMeasures ? "All" : "\(loop.startMeasure)-\(loop.endMeasure)")
                    .font(.system(size: 12, weight: isSelected ? .bold : .medium))
                    .foregroundColor(isSelected ? .white : .white.opacity(0.7))
                
                if let onRemove = onRemove {
                    Button(action: onRemove) {
                        Image(systemName: "xmark")
                            .font(.system(size: 8, weight: .bold))
                            .foregroundColor(.red.opacity(0.7))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(backgroundColor)
            )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    MeasureSelectorView()
        .environment(MainContainer())
}
