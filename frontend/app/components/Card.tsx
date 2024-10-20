"use client";

export default function Card({
  title,
  bal,
  disabled,
  input,
  setInput,
}: {
  title: string;
  bal: string;
  disabled: boolean;
  input: number | null;
  setInput: any;
}) {
  return (
    <div className="w-full rounded-lg p-3 bg-[#1E293B]">
      <div className="w-full">
        <h1 className="text-sm">{title}</h1>
        <input
          placeholder="0.0"
          type="number"
          className="bg-inherit outline-none text-3xl"
          disabled={disabled}
          onChange={(e) => setInput(e.target.value)}
          value={input ?? ""}
        />
      </div>
      <div className="w-full flex justify-end">
        <p className="text-sm">Balance: {bal} wei</p>
      </div>
    </div>
  );
}
